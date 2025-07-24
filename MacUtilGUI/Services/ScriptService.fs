namespace MacUtilGUI.Services

open System
open System.IO
open System.Diagnostics
open System.Reflection
open System.Threading.Tasks
open System.Text
open Tomlyn
open MacUtilGUI.Models

module ScriptService =

    let assembly = Assembly.GetExecutingAssembly()

    // Function to check if a script needs elevation (contains sudo, $ESCALATION_TOOL, etc.)
    let needsElevation (scriptContent: string) : bool =
        scriptContent.Contains("sudo ")
        || scriptContent.Contains("$ESCALATION_TOOL")
        || scriptContent.Contains("${ESCALATION_TOOL}")
        || scriptContent.Contains("/usr/bin/sudo")
        || scriptContent.Contains("/bin/sudo")

    let getEmbeddedResource (resourcePath: string) : string option =
        try
            // How F# handles embedded resources:
            // 1. Resource names are case-sensitive.
            // 2. They use the format "Namespace.Folder.FileName" with folders separated by dots.
            // 3. Hyphens in the directories are converted to underscores in the resource name.
            // 4. Hyphens in the filename are kept as-is.
            //    For example, "script-common/common-script.sh" becomes "MacUtilGUI.scripts_common.common-script.sh".
            // 5. The namespace is typically the assembly name, so we prefix it with "MacUtilGUI.".

            let pathParts = resourcePath.Replace("\\", "/").Split('/')

            let convertedParts =
                pathParts
                |> Array.mapi (fun i part ->
                    if i = pathParts.Length - 1 then
                        // Last part is filename - keep hyphens
                        part
                    else
                        // Directory parts - convert hyphens to underscores
                        part.Replace("-", "_"))

            let convertedPath = String.Join(".", convertedParts)
            let resourceName = sprintf "MacUtilGUI.%s" convertedPath

            printfn "DEBUG: Resource path '%s' -> '%s'" resourcePath resourceName

            use stream = assembly.GetManifestResourceStream(resourceName)

            if stream <> null then
                use reader = new StreamReader(stream)
                Some(reader.ReadToEnd())
            else
                printfn "Resource not found: %s" resourceName
                None
        with ex ->
            printfn "Error reading embedded resource %s: %s" resourcePath ex.Message
            None

    let listEmbeddedResources () =
        let resourceNames = assembly.GetManifestResourceNames()
        printfn "Available embedded resources:"

        for name in resourceNames do
            printfn "  %s" name

    let scriptsBasePath = ""

    let loadScriptsFromDirectory (directoryPath: string) : ScriptCategory list =
        let mutable categories = []

        try
            let tabDataPath = sprintf "%s/tab_data.toml" directoryPath

            match getEmbeddedResource tabDataPath with
            | Some content ->
                try
                    let tomlDoc = Toml.Parse(content)

                    // Parse the TOML as a dynamic table
                    if tomlDoc.Diagnostics.Count > 0 then
                        printfn "TOML parsing warnings/errors for %s:" tabDataPath

                        for diag in tomlDoc.Diagnostics do
                            printfn "  %s" (diag.ToString())

                    let table = tomlDoc.ToModel()

                    // Look for 'data' array in the table
                    if table.ContainsKey("data") then
                        match table.["data"] with
                        | :? Tomlyn.Model.TomlTableArray as dataArray ->
                            for dataGroup in dataArray do
                                if dataGroup.ContainsKey("name") && dataGroup.ContainsKey("entries") then
                                    let groupName = dataGroup.["name"].ToString()

                                    match dataGroup.["entries"] with
                                    | :? Tomlyn.Model.TomlTableArray as entriesArray ->
                                        let scripts =
                                            [ for entry in entriesArray do
                                                  if
                                                      entry.ContainsKey("name")
                                                      && entry.ContainsKey("description")
                                                      && entry.ContainsKey("script")
                                                  then
                                                      let name = entry.["name"].ToString()
                                                      let description = entry.["description"].ToString()
                                                      let script = entry.["script"].ToString()
                                                      let fullPath = sprintf "%s/%s" directoryPath script

                                                      yield
                                                          { Name = name
                                                            Description = description
                                                            Script = script
                                                            TaskList = "I"
                                                            Category = groupName
                                                            FullPath = fullPath } ]

                                        if not scripts.IsEmpty then
                                            let category = { Name = groupName; Scripts = scripts }
                                            categories <- category :: categories
                                    | _ -> ()
                        | _ -> ()
                with ex ->
                    printfn "Error parsing TOML file %s: %s" tabDataPath ex.Message
            | None ->
                printfn "ERROR: Embedded resource not found: %s" tabDataPath
                printfn "This should not happen if resources are properly embedded!"
        with ex ->
            printfn "Error loading scripts from %s: %s" directoryPath ex.Message

        categories |> List.rev

    let loadAllScripts () : ScriptCategory list =
        let mutable allCategories = []

        try
            // Quick check of embedded resources
            let resourceNames = assembly.GetManifestResourceNames()

            printfn
                "INFO: Found %d embedded resources including common-script.sh: %b"
                resourceNames.Length
                (resourceNames |> Array.exists (fun name -> name.EndsWith("common-script.sh")))

            let mainTabsPath = "tabs.toml"

            match getEmbeddedResource mainTabsPath with
            | Some content ->
                let tomlDoc = Toml.Parse(content)
                let table = tomlDoc.ToModel()

                if table.ContainsKey("directories") then
                    match table.["directories"] with
                    | :? Tomlyn.Model.TomlArray as dirArray ->
                        for dir in dirArray do
                            let directory = dir.ToString()
                            let categories = loadScriptsFromDirectory directory
                            allCategories <- allCategories @ categories
                    | _ -> ()
            | None ->
                printfn "ERROR: Main tabs.toml not found in embedded resources!"
                printfn "This should not happen if resources are properly embedded!"
        with ex ->
            printfn "Error loading scripts: %s" ex.Message

        allCategories

    // Main script execution function with real-time output streaming
    let runScript (scriptInfo: ScriptInfo) (onOutput: string -> unit) (onError: string -> unit) : Task<int> =
        Task.Run(fun () ->
            try
                // Detect OS platform to avoid non-UNIX systems
                if Environment.OSVersion.Platform <> PlatformID.Unix then
                    raise (System.Exception("Not running on UNIX!"))

                // Now detect if it isn't running on macOS with osascript checks
                if not (System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform Runtime.InteropServices.OSPlatform.OSX) then
                    raise (System.Exception("Not running on macOS"))

                // Get the script content from embedded resources
                match getEmbeddedResource scriptInfo.FullPath with
                | Some scriptContent ->
                    // Check if script sources common-script.sh
                    let needsCommonScript =
                        scriptContent.Contains(". ../common-script.sh")
                        || scriptContent.Contains(". ../../common-script.sh")

                    let finalScriptContent =
                        if needsCommonScript then
                            onOutput "DEBUG: Script needs common-script.sh, checking embedded resources..."

                            // Get common script content
                            match getEmbeddedResource "common-script.sh" with
                            | Some commonContent ->
                                onOutput "DEBUG: Successfully found common-script.sh in embedded resources"
                                // Remove sourcing line and combine scripts
                                let cleanedScript =
                                    scriptContent
                                        .Replace(". ../common-script.sh", "")
                                        .Replace(". ../../common-script.sh", "")
                                        .Trim()

                                // Combine: shebang + common functions + original script (without sourcing)
                                let shebang = "#!/bin/sh -e\n\n"

                                let commonFunctions =
                                    commonContent
                                        .Replace("#!/bin/sh -e", "")
                                        .Replace("# shellcheck disable=SC2034", "")
                                        .Trim()

                                sprintf
                                    "%s# Embedded common script functions\n%s\n\n# Original script content\n%s"
                                    shebang
                                    commonFunctions
                                    cleanedScript
                            | None ->
                                onError
                                    "Warning: common-script.sh not found in embedded resources, using original script"

                                scriptContent
                        else
                            scriptContent

                    // Check if script needs elevation
                    if needsElevation finalScriptContent then
                        onOutput "Script requires administrator privileges..."

                        // Replace $ESCALATION_TOOL with empty string since we'll handle elevation via osascript
                        let cleanedScript =
                            finalScriptContent
                                .Replace("$ESCALATION_TOOL ", "")
                                .Replace("${ESCALATION_TOOL} ", "")
                                .Replace("sudo ", "")

                        // Create a temporary script file for elevation
                        let tempDir = Path.GetTempPath()
                        let scriptFileName = Path.GetFileName(scriptInfo.Script)

                        let tempFileName =
                            sprintf "%s_%s" (Guid.NewGuid().ToString("N").Substring(0, 8)) scriptFileName

                        let tempFilePath = Path.Combine(tempDir, tempFileName)

                        try
                            // Write script content to temporary file
                            File.WriteAllText(tempFilePath, cleanedScript)

                            // Make the temporary file executable
                            let chmodStartInfo = ProcessStartInfo()
                            chmodStartInfo.FileName <- "/bin/chmod"
                            chmodStartInfo.Arguments <- sprintf "+x \"%s\"" tempFilePath
                            chmodStartInfo.UseShellExecute <- false
                            chmodStartInfo.CreateNoWindow <- true
                            let chmodProc = Process.Start(chmodStartInfo)

                            if chmodProc <> null then
                                chmodProc.WaitForExit()

                            onOutput "Prompting for administrator password..."

                            // Use osascript to run the script with elevated privileges
                            // Note: osascript doesn't provide real-time output, so we'll get all output at the end
                            let escapedPath = tempFilePath.Replace("\"", "\\\"")

                            let osascriptCommand =
                                sprintf
                                    """osascript -e 'do shell script "\"%s\"" with administrator privileges'"""
                                    escapedPath

                            let startInfo = ProcessStartInfo()
                            startInfo.FileName <- "/bin/sh"
                            startInfo.Arguments <- sprintf "-c \"%s\"" osascriptCommand
                            startInfo.UseShellExecute <- false
                            startInfo.CreateNoWindow <- true
                            startInfo.RedirectStandardOutput <- true
                            startInfo.RedirectStandardError <- true

                            let proc = Process.Start(startInfo)

                            if proc <> null then
                                onOutput "Script is running with administrator privileges..."
                                onOutput "Note: Output will appear when script completes (osascript limitation)"

                                // Wait for the process to complete
                                proc.WaitForExit()

                                // Get all output at once (osascript limitation)
                                let output = proc.StandardOutput.ReadToEnd()
                                let error = proc.StandardError.ReadToEnd()

                                // Display output line by line for better readability
                                if not (String.IsNullOrEmpty(output)) then
                                    let lines = output.Split([| '\n'; '\r' |], StringSplitOptions.RemoveEmptyEntries)

                                    for line in lines do
                                        onOutput line

                                if not (String.IsNullOrEmpty(error)) then
                                    let lines = error.Split([| '\n'; '\r' |], StringSplitOptions.RemoveEmptyEntries)

                                    for line in lines do
                                        onError line

                                onOutput (sprintf "Script completed: %s (Exit Code: %d)" scriptInfo.Name proc.ExitCode)
                                proc.ExitCode
                            else
                                let errorMsg = sprintf "Failed to start elevated script: %s" scriptInfo.Name
                                onError errorMsg
                                -1
                        finally
                            // Clean up temporary file
                            if File.Exists(tempFilePath) then
                                try
                                    File.Delete(tempFilePath)
                                with _ ->
                                    () // Ignore cleanup errors
                    else
                        // Script doesn't need elevation, run normally
                        let tempDir = Path.GetTempPath()
                        let scriptFileName = Path.GetFileName(scriptInfo.Script)

                        let tempFileName =
                            sprintf "%s_%s" (Guid.NewGuid().ToString("N").Substring(0, 8)) scriptFileName

                        let tempFilePath = Path.Combine(tempDir, tempFileName)

                        try
                            // Write script content to temporary file
                            File.WriteAllText(tempFilePath, finalScriptContent)

                            // Make the temporary file executable
                            let chmodStartInfo = ProcessStartInfo()
                            chmodStartInfo.FileName <- "/bin/chmod"
                            chmodStartInfo.Arguments <- sprintf "+x \"%s\"" tempFilePath
                            chmodStartInfo.UseShellExecute <- false
                            chmodStartInfo.CreateNoWindow <- true

                            let chmodProc = Process.Start(chmodStartInfo)

                            if chmodProc <> null then
                                chmodProc.WaitForExit()

                            // Execute the script with real-time output
                            let startInfo = ProcessStartInfo()
                            startInfo.FileName <- "/bin/bash"
                            startInfo.Arguments <- sprintf "\"%s\"" tempFilePath
                            startInfo.UseShellExecute <- false
                            startInfo.CreateNoWindow <- true
                            startInfo.RedirectStandardOutput <- true
                            startInfo.RedirectStandardError <- true

                            let proc = Process.Start(startInfo)

                            if proc <> null then
                                // Set up async reading of output streams
                                let outputBuilder = StringBuilder()
                                let errorBuilder = StringBuilder()

                                // Handle output data received events
                                proc.OutputDataReceived.Add(fun args ->
                                    if not (String.IsNullOrEmpty(args.Data)) then
                                        outputBuilder.AppendLine(args.Data) |> ignore
                                        onOutput args.Data)

                                proc.ErrorDataReceived.Add(fun args ->
                                    if not (String.IsNullOrEmpty(args.Data)) then
                                        errorBuilder.AppendLine(args.Data) |> ignore
                                        onError args.Data)

                                // Start async reading
                                proc.BeginOutputReadLine()
                                proc.BeginErrorReadLine()

                                // Wait for the process to complete
                                proc.WaitForExit()

                                onOutput (sprintf "Script completed: %s (Exit Code: %d)" scriptInfo.Name proc.ExitCode)
                                proc.ExitCode
                            else
                                let errorMsg = sprintf "Failed to start script: %s" scriptInfo.Name
                                onError errorMsg
                                -1
                        finally
                            // Clean up temporary file
                            if File.Exists(tempFilePath) then
                                try
                                    File.Delete(tempFilePath)
                                with _ ->
                                    () // Ignore cleanup errors
                | None ->
                    let errorMsg =
                        sprintf "Script content not found in embedded resources: %s" scriptInfo.FullPath

                    onError errorMsg
                    -1
            with ex ->
                let errorMsg = sprintf "Error running script %s: %s" scriptInfo.Name ex.Message
                onError errorMsg
                -1)

    // Alternative version that returns an IObservable for reactive programming
    let runScriptObservable (scriptInfo: ScriptInfo) : IObservable<Choice<string, string, int>> =
        { new IObservable<Choice<string, string, int>> with
            member __.Subscribe(observer) =
                let task =
                    Task.Run(fun () ->
                        try
                            // Get the script content from embedded resources
                            match getEmbeddedResource scriptInfo.FullPath with
                            | Some scriptContent ->
                                // Check if script sources common-script.sh
                                let needsCommonScript =
                                    scriptContent.Contains(". ../common-script.sh")
                                    || scriptContent.Contains(". ../../common-script.sh")

                                let finalScriptContent =
                                    if needsCommonScript then
                                        observer.OnNext(
                                            Choice1Of3
                                                "DEBUG: Script needs common-script.sh, checking embedded resources..."
                                        )

                                        // Get common script content
                                        match getEmbeddedResource "common-script.sh" with
                                        | Some commonContent ->
                                            observer.OnNext(
                                                Choice1Of3
                                                    "DEBUG: Successfully found common-script.sh in embedded resources"
                                            )
                                            // Remove sourcing line and combine scripts
                                            let cleanedScript =
                                                scriptContent
                                                    .Replace(". ../common-script.sh", "")
                                                    .Replace(". ../../common-script.sh", "")
                                                    .Trim()

                                            // Combine: shebang + common functions + original script (without sourcing)
                                            let shebang = "#!/bin/sh -e\n\n"

                                            let commonFunctions =
                                                commonContent
                                                    .Replace("#!/bin/sh -e", "")
                                                    .Replace("# shellcheck disable=SC2034", "")
                                                    .Trim()

                                            sprintf
                                                "%s# Embedded common script functions\n%s\n\n# Original script content\n%s"
                                                shebang
                                                commonFunctions
                                                cleanedScript
                                        | None ->
                                            observer.OnNext(
                                                Choice2Of3
                                                    "Warning: common-script.sh not found in embedded resources, using original script"
                                            )

                                            scriptContent
                                    else
                                        scriptContent

                                // Create a temporary file to execute the script
                                let tempDir = Path.GetTempPath()
                                let scriptFileName = Path.GetFileName(scriptInfo.Script)

                                let tempFileName =
                                    sprintf "%s_%s" (Guid.NewGuid().ToString("N").Substring(0, 8)) scriptFileName

                                let tempFilePath = Path.Combine(tempDir, tempFileName)

                                try
                                    // Write script content to temporary file
                                    File.WriteAllText(tempFilePath, finalScriptContent)

                                    // Make the temporary file executable
                                    let chmodStartInfo = ProcessStartInfo()
                                    chmodStartInfo.FileName <- "/bin/chmod"
                                    chmodStartInfo.Arguments <- sprintf "+x \"%s\"" tempFilePath
                                    chmodStartInfo.UseShellExecute <- false
                                    chmodStartInfo.CreateNoWindow <- true

                                    let chmodProc = Process.Start(chmodStartInfo)

                                    if chmodProc <> null then
                                        chmodProc.WaitForExit()

                                    // Execute the script with real-time output
                                    let startInfo = ProcessStartInfo()
                                    startInfo.FileName <- "/bin/bash"
                                    startInfo.Arguments <- sprintf "\"%s\"" tempFilePath
                                    startInfo.UseShellExecute <- false
                                    startInfo.CreateNoWindow <- true
                                    startInfo.RedirectStandardOutput <- true
                                    startInfo.RedirectStandardError <- true

                                    let proc = Process.Start(startInfo)

                                    if proc <> null then
                                        // Handle output data received events
                                        proc.OutputDataReceived.Add(fun args ->
                                            if not (String.IsNullOrEmpty(args.Data)) then
                                                observer.OnNext(Choice1Of3 args.Data))

                                        proc.ErrorDataReceived.Add(fun args ->
                                            if not (String.IsNullOrEmpty(args.Data)) then
                                                observer.OnNext(Choice2Of3 args.Data))

                                        // Start async reading
                                        proc.BeginOutputReadLine()
                                        proc.BeginErrorReadLine()

                                        // Wait for the process to complete
                                        proc.WaitForExit()

                                        observer.OnNext(Choice3Of3 proc.ExitCode)
                                        observer.OnCompleted()
                                    else
                                        observer.OnNext(
                                            Choice2Of3(sprintf "Failed to start script: %s" scriptInfo.Name)
                                        )

                                        observer.OnCompleted()
                                finally
                                    // Clean up temporary file
                                    if File.Exists(tempFilePath) then
                                        try
                                            File.Delete(tempFilePath)
                                        with _ ->
                                            () // Ignore cleanup errors
                            | None ->
                                observer.OnNext(
                                    Choice2Of3(
                                        sprintf
                                            "Script content not found in embedded resources: %s"
                                            scriptInfo.FullPath
                                    )
                                )

                                observer.OnCompleted()
                        with ex ->
                            observer.OnNext(
                                Choice2Of3(sprintf "Error running script %s: %s" scriptInfo.Name ex.Message)
                            )

                            observer.OnCompleted())

                { new IDisposable with
                    member __.Dispose() =
                        // Could cancel the task here if needed
                        () } }

namespace MacUtilGUI.Services;

using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;
using System.Collections.Generic;
using Tomlyn;
using MacUtilGUI.Models;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Avalonia.Controls.Converters;

public class ScriptService {

    static Assembly assembly = Assembly.GetExecutingAssembly();

    public static String getEmbeddedResource(String resourcePath) {
        try
        {
            String resourceName = String.Format("MacUtilGUI.{0}", resourcePath.Replace("/", ".").Replace("\\", ".").Replace("-", "_"));
            using (var resStream = assembly.GetManifestResourceStream(resourceName))
            {
                if (resStream is not null)
                {
                    var reader = new StreamReader(resStream);
                    return reader.ReadToEnd();
                }
                else
                {
                    Console.WriteLine(String.Format("Resource not found: {0}", resourceName));
                    return "";
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(String.Format("Error reading embedded resource {0}: {1}", resourcePath, ex.Message));
        }
        return "";
    }

    public static void listEmbeddedResources() {
        var resourceNames = assembly.GetManifestResourceNames();
        Console.WriteLine("Available embedded resources:");
        foreach (String name in resourceNames) {
            Console.WriteLine(String.Format("  {0}", name));
        }
    }

    public static List<ScriptCategory> loadScriptsFromDirectory(String directoryPath) {
        List<ScriptCategory> categories = [];

        try
        {
            String tabDataPath = String.Format("{0}/tab_data.toml", directoryPath);
            String content = getEmbeddedResource(tabDataPath);

            if (!String.IsNullOrEmpty(content))
            {
                try
                {
                    var tomlDoc = Toml.Parse(content);

                    if (tomlDoc.Diagnostics.Count > 0)
                    {
                        Console.WriteLine(String.Format("TOML parsing warnings/errors for {0}", tabDataPath));
                        foreach (var diag in tomlDoc.Diagnostics)
                        {
                            Console.WriteLine(String.Format("  {0}", diag.ToString()));
                        }
                    }

                    var table = tomlDoc.ToModel();

                    if (table.ContainsKey("data") && table["data"] is Tomlyn.Model.TomlTableArray dataArray)
                    {
                        foreach (var dataGroup in dataArray)
                        {
                            if (dataGroup.ContainsKey("name") && dataGroup.ContainsKey("entries"))
                            {
                                String groupName = dataGroup["name"].ToString();
                                if (dataGroup["entries"] is Tomlyn.Model.TomlTableArray entriesArray)
                                {
                                    var scripts = new List<ScriptInfo>();
                                    foreach (var entry in entriesArray)
                                    {
                                        if (entry.ContainsKey("name") && entry.ContainsKey("description"))
                                        {
                                            scripts.Add(new ScriptInfo
                                            {
                                                Name = entry["name"].ToString(),
                                                Description = entry["description"].ToString(),
                                                Script = entry["script"].ToString(),
                                                TaskList = "I",
                                                Category = groupName,
                                                FullPath = $"{directoryPath}/{entry["script"].ToString()}"
                                            });     // we don't need to create variables we're only going to use once
                                        }
                                    }

                                    if (scripts.Count > 0)
                                    {
                                        categories.Add(new ScriptCategory
                                        {
                                            Name = groupName,
                                            Scripts = scripts
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine(String.Format("Error parsing TOML file {0}: {1}", tabDataPath, ex.Message));
                }
            }
            else
            {
                Console.WriteLine(String.Format("ERROR: Embedded resource not found: {0}", tabDataPath));
                Console.WriteLine("This should not happen if resources are properly embedded!");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(String.Format("Error loading scripts from {0}: {1}", directoryPath, ex.Message));
        }
        categories.Reverse();
        return categories;
    }

    public static List<ScriptCategory> loadAllScripts() {
        List<ScriptCategory> allCategories = [];

        try
        {
            if (Debugger.IsAttached)
            {
                // We'll leave this for the debugger
                listEmbeddedResources();
            }

            String mainTabsPath = "tabs.toml";
            String content = getEmbeddedResource(mainTabsPath);
            if (!String.IsNullOrEmpty(content))
            {
                var tomlDoc = Toml.Parse(content);
                var table = tomlDoc.ToModel();

                if (table.ContainsKey("directories") && table["directories"] is Tomlyn.Model.TomlArray dirArray)
                {
                    foreach (var dir in dirArray)
                    {
                        allCategories.AddRange(loadScriptsFromDirectory(dir.ToString()));
                    }
                }
            }
            else
            {
                Console.WriteLine("ERROR: Main tabs.toml not found in embedded resources!");
                Console.WriteLine("This should not happen if resources are properly embedded!");
            }

        }
        catch (Exception ex)
        {
            Console.WriteLine(String.Format("Error loading scripts: {0}", ex.Message));
        }
        return allCategories;
    }

    public static String RunScript(ScriptInfo scriptInfo)
    {
        try
        {
            String scriptContent = getEmbeddedResource(scriptInfo.FullPath);    // We first get the script and then do all processing required
            if (!String.IsNullOrEmpty(scriptContent))
            {
                // Creating temp files, setting them up with data, running them...
                String tempDir = Path.GetTempPath();
                String scriptFileName = Path.GetFileName(scriptInfo.Script);    // equivalent of basename command in a UNIX terminal

                // This yields strings like "20dc002f_fix_finder.sh". We combine this name with the %TEMP% path, and presto! We have a file path
                String tempFileName = String.Format("{0}_{1}", Guid.NewGuid().ToString("N").Substring(0, 8), scriptFileName);
                String tempFilePath = Path.Combine(tempDir, tempFileName);

                try
                {
                    File.WriteAllText(tempFilePath, scriptContent);

                    // Since we're talking about a UNIX environment, we'll mark the script as executable
                    // .NET is cross-platform, so it's a good idea we check the platform we're running this on before running chmod

                    // macOS yields Unix
                    if (Environment.OSVersion.Platform == PlatformID.Unix)
                    {
                        Process.Start("/bin/chmod", $"+x \"{tempFilePath}\"").WaitForExit();
                    }
                    else
                    {
                        throw new Exception("Not running on UNIX!");
                    }

                    Process proc = new Process();
                    proc.StartInfo = new ProcessStartInfo
                    {
                        FileName = "/bin/bash",
                        Arguments = $"\"{tempFilePath}\"",
                        UseShellExecute = false,
                        CreateNoWindow = true,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    };

                    String output = "";
                    String error = "";

                    proc.Start();
                    if (proc is not null)
                    {
                        output = proc.StandardOutput.ReadToEnd();
                        error = proc.StandardError.ReadToEnd();
                    }
                    proc.WaitForExit();

                    var fullOutput = String.IsNullOrEmpty(error) ? output : String.Format("{0}\n--- ERRORS ---\n{1}", output, error);
                    Console.WriteLine(String.Format("Executed script: {0} (Exit Code: {1})", scriptInfo.Name, proc.ExitCode));

                    return fullOutput;
                }
                finally
                {
                    // Clean up stuff
                    if (File.Exists(tempFilePath))
                    {
                        try
                        {
                            File.Delete(tempFilePath);
                        }
                        catch
                        {
                            // Do nothing
                        }
                    }
                }
            }
            else
            {
                String errorMsg = String.Format("Script content not found in embedded resource: {0}", scriptInfo.FullPath);
                Console.Write(errorMsg);
                return errorMsg;
            }
        }
        catch (Exception ex)
        {
            String errorMsg = String.Format("Error running script {0}: {1}", scriptInfo.Name, ex.Message);
            Console.Write(errorMsg);
            return errorMsg;
        }
    }
}
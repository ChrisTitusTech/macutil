using System;
using System.Collections.Generic;
using Microsoft.CodeAnalysis;

namespace MacUtilGUI.Models;

public class ScriptCategory {
    public string Name {get; set;}
    public List<ScriptInfo> Scripts {get; set;}
}

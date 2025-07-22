namespace MacUtilGUI.ViewModels;

using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows.Input;
using Avalonia.Threading;
using MacUtilGUI.Models;
using MacUtilGUI.Services;

public class RelayCommand : ICommand
{
    private readonly Func<object, bool> _canExecute;
    private readonly Action<object> _execute;

    public RelayCommand(Action<object> execute) : this(_ => true, execute) { }

    public RelayCommand(Func<object, bool> canExecute, Action<object> execute)
    {
        _canExecute = canExecute ?? throw new ArgumentNullException(nameof(canExecute));
        _execute = execute ?? throw new ArgumentNullException(nameof(execute));
    }

    public event EventHandler CanExecuteChanged;
    public bool CanExecute(object parameter) => _canExecute(parameter);
    public void Execute(object parameter) => _execute(parameter);
    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);
}

public class MainWindowViewModel : ViewModelBase
{
    private ScriptInfo _selectedScript;
    private String _scriptOutput = String.Empty;
    private readonly ObservableCollection<ScriptCategory> _categories = new();
    public String Title = "MacUtil GUI - Script Runner";

    public MainWindowViewModel()
    {
        SelectScriptCommand = new RelayCommand(parameter =>
        {
            if (parameter is ScriptInfo script)
            {
                _selectedScript = script;
                _scriptOutput = String.Empty;
                OnPropertyChanged("SelectedScript");
                OnPropertyChanged("ScriptOutput");
                OnPropertyChanged("CanRunScript");
                OnPropertyChanged("SelectedScriptName");
                OnPropertyChanged("SelectedScriptDescription");
                OnPropertyChanged("SelectedScriptCategory");
                OnPropertyChanged("SelectedScriptFile");
            }
        });

        RunScriptCommand = new RelayCommand(_ =>
        {
            if (_selectedScript is not null)
            {
                _scriptOutput = "Running script";
                OnPropertyChanged("ScriptOutput");

                Task.Run(() =>
                {
                    var output = ScriptService.RunScript(_selectedScript);

                    // Allow some threading
                    Dispatcher.UIThread.InvokeAsync(() =>
                    {
                        _scriptOutput = output;
                        OnPropertyChanged("ScriptOutput");
                    });
                });
            }
        });

        List<ScriptCategory> loadedCategories = ScriptService.loadAllScripts();
        foreach (ScriptCategory category in loadedCategories)
        {
            _categories.Add(category);
        }   
    }

    public ObservableCollection<ScriptCategory> Categories => _categories;
    public ScriptInfo SelectedScript => _selectedScript;
    public String ScriptOutput => _scriptOutput;
    public String SelectedScriptName => (_selectedScript is not null) ? _selectedScript.Name : "";
    public String SelectedScriptDescription => (_selectedScript is not null) ? _selectedScript.Description : "";
    public String SelectedScriptCategory => (_selectedScript is not null) ? _selectedScript.Category : "";
    public String SelectedScriptFile => (_selectedScript is not null) ? _selectedScript.Script : "";
    public bool CanRunScript => _selectedScript is not null;
    public ICommand SelectScriptCommand { get; }

    public ICommand RunScriptCommand { get; }
}
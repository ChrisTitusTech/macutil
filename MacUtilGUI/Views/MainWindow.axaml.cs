namespace MacUtilGUI.Views;

using System.Windows.Input;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Avalonia.Interactivity;
using MacUtilGUI.ViewModels;
using MacUtilGUI.Models;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void InitializeComponent()
    {
        AvaloniaXamlLoader.Load(this);
    }

    private void OnScriptButtonClick(object sender, RoutedEventArgs e)
    {
        if (sender is Button button && 
            button.Tag is ScriptInfo script && 
            DataContext is MainWindowViewModel vm)
        {
            ((ICommand)vm.SelectScriptCommand).Execute(script);
        }
    }
}
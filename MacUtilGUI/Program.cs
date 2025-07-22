namespace MacUtilGUI;
using System;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using MacUtilGUI.Views;
using MacUtilGUI.ViewModels;
using Microsoft.CodeAnalysis.CSharp.Syntax;

public class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            desktop.MainWindow = new MainWindow
            {
                DataContext = new MainWindowViewModel()
            };

            base.OnFrameworkInitializationCompleted();
        }
    }
}

internal static class Program
{
    public static AppBuilder BuildAvaloniaApp() => AppBuilder.Configure<App>().UsePlatformDetect().LogToTrace();

    [STAThread]
    public static void Main(String[] args)
    {
        BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);
    }
}
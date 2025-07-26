namespace MacUtilGUI.Views

open System.Windows.Input
open Avalonia
open Avalonia.Controls
open Avalonia.Markup.Xaml
open Avalonia.Interactivity
open MacUtilGUI.ViewModels
open MacUtilGUI.Models

type MainWindow() as this =
    inherit Window()

    do this.InitializeComponent()

    member private this.InitializeComponent() = AvaloniaXamlLoader.Load(this)

    member private this.OnCloseButtonClick(sender: obj, e: RoutedEventArgs) =
        this.Close()

    member private this.OnMinimizeButtonClick(sender: obj, e: RoutedEventArgs) =
        this.WindowState <- WindowState.Minimized

    member private this.OnMaximizeButtonClick(sender: obj, e: RoutedEventArgs) =
        this.WindowState <-
            if this.WindowState = WindowState.FullScreen then
                WindowState.Normal
            else
                WindowState.FullScreen

    member private this.OnScriptButtonClick(sender: obj, e: RoutedEventArgs) =
        match sender with
        | :? Button as button ->
            match button.Tag with
            | :? ScriptInfo as script ->
                match this.DataContext with
                | :? MainWindowViewModel as vm -> (vm.SelectScriptCommand :> ICommand).Execute(script)
                | _ -> ()
            | _ -> ()
        | _ -> ()

using Godot;
using System;
using System.Collections.Generic;

public partial class DialogManager : Node
{
    public DialogManager Instance { get; private set; }

    [Signal]
    public delegate void DialogStarted();
    [Signal]
    public delegate void DialogLineChanged(DialogLine line);
    [Signal]
    public delegate void DialogFinished();
    [Signal]
    public delegate void DialogTargetChanged(Node3D target);
    [Signal]
    public delegate void AutoAdvanceRequest();

    private CameraController _camera;
    private List<DialogLine> _lines = new();
    private bool _active = false;
    private int _currentIndex = 0;
    private Node3D _currentTarget;

    private bool _autoMode = false;
    private bool _paused = false;

    [Export]
    private float _autoDelay = 5.0f;
    private float _autoTimer = 0.0f;

    public override void _Ready()
    {
        Instance = this;
    }

    public override void _Process(double delta)
    {
        if (!_active || !_autoMode)
        {
            return;
        }

        _autoTimer += (float)delta;

        if (_autoTimer >= _autoDelay)
        {
            _autoTimer = 0.0f;
            EmitSignal(SignalName.AutoAdvanceRequest);
        }
    }

    public void RegisterCamera(CameraController cam)
    {
        if (_camera != null && _camera != cam)
        {
            GD.PushWarning("DialogManager already has a camera registered");
        }
        _camera = cam;
    }

    public void StartDialog(List<DialogLine> NewLines)
    {
        GD.Print("Start dialog has been called in DialogManager");

        if (active)
        {
            GD.Print($"DialogManager active state: {_active}");
            return;
        }

        if (NewLines.Count == 0)
        {
            GD.Print("DialogManager recieved no dialog lines.");
        }

        _lines = NewLines;
        _currentIndex = 0;
        _autoTimer = 0.0f;
        _active = true;

        GameStateManager.Instance.EnterDialog();
        EmitSignal(SignalName.DialogStarted);

        ShowCurrentLine();
    }

    private void ShowCurrentLine()
    {
        GD.Print("===SHOW CURRENT LINE===");
        GD.Print($"Total Lines: {_lines.Count}");
        GD.Print($"Current Index: {_currentIndex}");

        if (_currentIndex >= _lines.Count)
        {
            FinishDialog();
            return;
        }

        GD.Print($"Line Size: {_lines.Count}");
        _autoTimer = 0.0f;

        DilogLine Line = _lines[_currentIndex];
        _currentTarget = _lines.Target;

        EmitSignal(SignalName.DialogLineChanged, Line);
        EmitSignal(SignalName.DialogTargetChanged, Line.Target);

        if (Line.Target && _camera)
        {
            GD.Print(Line.Target);
            _camera.FocusOn(Line.Target);
        }
    }

    private void AdvanceDialog()
    {
        if (!_active)
        {
            return;
        }

        _currentIndex += 1;
        ShowCurrentLine();
    }

    private void FinishDialog()
    {
        if (!active)
        {
            return;
        }

        _active = false;
        _lines.Clear();
        _currentTarget = null;

        if (_camera)
        {
            _camera.ReleaseFocus();
        }

        EmitSignal(SignalName.DialogFinished);
        EmitSignal(SignalName.DialogTargetChanged, null);

        GameStateManager.Instance.ExitDialog();
    }
}
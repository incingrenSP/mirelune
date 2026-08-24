using Godot;

public partial class DialogUI : Control
{
	[Export]
	private Label SpeakerLabel { get; set; }
	[Export]
	private RichTextLabel TextLabel { get; set; }
	[Export]
	private Button PauseButton;
	[Export]
	private Button LogButton;
	[Export]
	private Button AutoButton;
	[Export]
	private Control DialogLog;
	[Export]
	private VBoxContainer LogVBox;

	[Export]
	private PauseMenu pauseMenu { get; set; }
	
	private static readonly PackedScene LogEntryScene = GD.Load<PackedScene>(
        "res://scenes/user_interface/dialogs/dialog_log_entry.tscn"
	);

	private bool _autoModeBeforeLog = false;

	public override void _Ready()
	{
		Visible = false;
		SpeakerLabel = GetNode<Label>("DialogBox/BoxPanel/SpeakerLabel");
		TextLabel = GetNode<Label>("DialogBox/BoxPanel/TextLabel");

		PauseButton = GetNode<Button>("Controls/Pause");
		LogButton = GetNode<Button>("Controls/Log");
		AutoButton = GetNode<Button>("Controls/Auto");

		DialogLog = GetNode<Control>("DialogLog");
		LogVBox = GetNode<VBoxContainer>("DialogLog/Panel/ScrollContainer/VBoxContainer");

		SpeakerLabel.AddThemeFontSizeOverride("SpeakerFontSize", 30);
		TextLabel.AddThemeFontSizeOverride("TextLabelFontSize", 24);

		DialogLog.Visible = false;

		LogButton.ToggleMode = true;
		AutoButton.ToggleMode = true;

		PauseButton.Pressed += OnPausePressed;
		LogButton.Toggled += OnLogToggled;
		AutoButton.Toggled += OnAutoToggled;

		TextLabel.PageShown += AddLogEntry;

		DialogManager.Instance.DialogStarted += OnDialogStarted;
		DialogManager.Instance.DialogLineChanged += OnDialogLineChanged;
		DialogManager.Instance.DialogFinished += OnDialogFinished;
		DialogManager.Instance.AutoAdvanceRequest += OnAutoAdvanceRequest;
	}

	public override void _UnhandledInput(InputEvent inputEvent)
	{
		if (!Visible)
		{
			return;
		}

		if (inputEvent.IsActionPressed("ui_accept") || inputEvent.IsActionPressed("interact"))
		{
			TryAdvance();
		}
	}

	private void TryAdvance()
	{
		if (DialogManager.Instance.Paused())
		{
			return;
		}

		if (TextLabel.revealing)
		{
			TextLabel.SkipReveal();
			return;
		}

		if (!TextLabel.AdvancePage())
		{
			DialogManager.Instance.AdvanceDialog();
		}
	}

	private void OnPausePressed()
	{
		GD.Print("Pause Button Pressed");
		pauseMenu.Open();
	}

	private void OnLogToggled(bool toggledOn)
	{
		GD.Print("Log Button Toggled");
		DialogLog.Visible = toggledOn;
		GetNode<VBoxContainer>("DialogBox").Visible = !toggledOn;

		if (toggledOn)
		{
			_autoModeBeforeLog = DialogManager.Instance._autoMode;
			AutoButton.SetPressedNoSignal(false);
			DialogManager.Instance._autoMode = _autoModeBeforeLog;
		}
		else
		{
			AutoButton.SetPressedNoSignal(_autoModeBeforeLog);
			DialogManager.Instance._autoMode = _autoModeBeforeLog;
		}
	}

	private void OnAutoToggled(bool toggledOn)
	{
		GD.Print("Auto Button Toggled");
		DialogManager.Instance.AutoMode = toggledOn;
	}

	private void OnDialogStarted()
	{
		Visible = true;
	}

}

using Godot;

public partial class PauseMenu : Control
{
    [Signal]
    public delegate void PauseOpened();
    [Signal]
    public delegate void PauseClosed();

    [Export]
    private Button _resumeButton;
    [Export]
    private Button _statsButton;
    [Export]
    private Button _skillsButton;

    [Export]
    private Control _content;
    [Export]
    public Control StatsPanel { get; private set; }
    [Export]
    public Control SkillsViewer { get; private set; }

    [Export]
    private Player player { get; set; }

    public override void _Ready()
    {
        ProcessMode = Node.ProcessModeAlways;

        _resumeButton = GetNode<Button>("Navigation/MenuButtons/Resume");
        _statsButton = GetNode<Button>("Navigation/MenuButtons/Stats");
        _skillsButton = GetNode<Button>("Navigation/MenuButtons/Skills");

        _content = GetNode<Control>("Content");
        StatsPanel = GetNode<Control>("Control/StatsView");
        SkillsViewer = GetNode<Control>("Control/SkillsViewer");

        this.Visible = false;
        StatsPanel.Visible = false;
        SkillsViewer.Visible = false;

        ResumeButton.Pressed += OnResumePressed;
        StatsButton.Pressed += OnStatsPressed;
        SkillsButton.Pressed += OnSkillsPressed;
    }

    public override void _Process(double delta)
    {
        StatsPanel.UpdateStats(player);
    }

    public void Open()
    {
        if (!GameStateManager.Instance.CanPause())
        {
            return;
        }

        GameStateManager.Instance.PauseGame();
        EmitSignal(SignalName.PauseOpened);
        this.Visible = true;
    }

    public void Close()
    {
        if (!GameStateManager.Instance.IsPause())
        {
            return;
        }

        GameStateManager.ResumeGame();
        EmitSignal(SignalName.PauseClosed);
        StatsPanel.Visible = false;
        SkillsViewer.Visible = false;
    }

    private void OnResumePressed()
    {
        Close();
    }

    private void OnStatsPressed()
    {
        ShowPanel(StatsPanel);
    }

    private void OnSkillsPressed()
    {
        SkillsViewer.Open(player);
        ShowPanel(SkillsViewer);
    }

    private void ShowPanel(Control panel)
    {
        foreach (Node child in _content.GetChildren())
        {
            child.Visible = false;
        }

        panel.Visible = true;
    }
}
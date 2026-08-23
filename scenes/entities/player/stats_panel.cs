using Godot;

public partial class StatsPanel : Control
{
    [Export]
    private Label TitleLabel;
    [Export]
    private Label NameLabel;
    [Export]
    private Label LevelLabel;
    [Export]
    private ProgressBar XpBar;
    [Export]
    private ProgressBar HpBar;
    [Export]
    private ProgressBar SpBar;
    [Export]
    private Label AtkValue;
    [Export]
    private Label DefValue;
    [Export]
    private Label SpdValue;
    [Export]
    private Label HpRegenValue;
    [Export]
    private Label SpRegenValue;
    [Export]
    private Label SkillSlotsValue;

    public override void _Ready()
    {
        TitleLabel = GetNode<Label>("Title");

        NameLabel = GetNode<Label>("PlayerInfo/PlayerName/NameL");
        LevelLabel = GetNode<Label>("PlayerInfo/PlayerName/LevelLabel");
        XpBar = GetNode<ProgressBar>("PlayerInfo/XPBar");

        HpBar = GetNode<ProgressBar>("ResourceBars/HPRow/HPBar");
        SpBar = GetNode<ProgressBar>("ResourceBars/SPRow/SPBar");

        AtkValue = GetNode<Label>("StatsGrid/MinorStats/ATK/ATKValue");
        DefValue = GetNode<Label>("StatsGrid/MinorStats/DEF/DEFValue");
        SpdValue = GetNode<Label>("StatsGrid/MinorStats/SPD/SPDValue");

        HpRegenValue = GetNode<Label>("StatsGrid/MajorStats/HPRegen/HPRegenValue");
        SpRegenValue = GetNode<Label>("StatsGrid/MajorStats/SPRegen/SPRegenValue");
        SkillSlotsValue = GetNode<Label>("StatsGrid/MajorStats/SkillSlots/SkillSlotsValue");
    }

    public void UpdateStats(Player player)
    {
        TitleLabel.AddThemeFontSizeOverride("title_font_size", 48);

        NameLabel.Text = $"{player.PlayerName}:";
        LevelLabel.Text = $"Lvl. {player.PlayerLevel}";

        XpBar.MaxValue = player.MaxXp;
        XpBar.Value = player.Xp;

        HpBar.MaxValue = player.MaxHp;
        HpBar.Value = player.Hp;
        HpBar.GetNode("HPValue").Text = $"{player.Hp}/{player.MaxHp}";

        SpBar.MaxValue = player.MaxSp;
        SpBar.Value = player.Sp;
        SpBar.GetNode("HPValue").Text = $"{player.Sp}/{player.MaxSp}";

        AtkValue.Text = $"{player.Atk}";
        DefValue.Text = $"{player.Def}";
        SpdValue.Text = $"{player.Spd}";

        HpRegenValue.text = $"{player.HpRegenRate}/s";
        SpRegenValue.text = $"{player.SpRegenRate}/s";

        SkillSlotsValue.Text = $"{player.GetTotalUnlockedSlots()}";


    }


}
using Godot;

public partial class SkillData : Resource
{
    public enum SkillCategory
    {
        Active,
        Passive,
        Core
    }

    private enum AttackType
    {
        PointAndClick,
        SkillShot,
        AreaOfEffect
    }

    [Export]
    public string Id {get ; set; } = "";
    [Export]
    public string DisplayName {get ; set; } = "";
    [Export]
    public string Description {get ; set; } = "";
    [Export]
    public SkillCategory Category {get ; set; }
    [Export]
    public Texture2D Icon {get ; set; } = null; 

    [Export]
    public int SpCost {get ; set; }
    [Export]
    public int Damage {get ; set; }
    
    [Export]
    public AttackType _attackType = AttackType.PointAndClick;
    [Export]
    public float range {get ; set; } = 2.0f;
}
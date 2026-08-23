using Godot;
using System;
using System.Collections.Generic;

public partial class SkillDatabase : Node
{
    private Dictionary<string, SkillData> _skills = new();

    public override void _Ready()
    {
        LoadAllSkills("res://skills/");
    }

    private void LoadAllSkills(string path)
    {
        DirAccess dir = DirAccess.Open(path);

        if (dir == null)
        {
            GD.PushError($"SkillDatabase could no open {path}");
            return;
        }

        dir.ListDirBegin();

        string fileName = dir.GetNext();

        while (fileName != "")
        {
            if (fileName.EndsWith(".tres"))
            {
                SkillData skill = GD.Load<SkillData>(path + fileName);
                _skills[skill.id] = skill;
            }
            fileName = dir.GetNext();
        }
        dir.ListDirEnd();
    }

    public SkillData GetSkill(string id)
    {
        return _skills.GetValueOrDefault(id);
    }
}
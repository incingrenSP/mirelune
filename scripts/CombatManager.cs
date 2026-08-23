using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public partial class CombatManager : Node
{
    public static CombatManager Instance { get; private set; }

    private List<Enemy> _combatants = new();

    [Signal]
    public delegate void CombatStarted();
    [Signal]
    public delegate void CombatEnded();
    [Signal]
    public delegate void CombatantAdded(Enemy enemy);
    [Signal]
    public delegate void CombatantRemoved(Enemy enemy);

    public override void _Ready()
    {
        Instance = this;
    }

    public void EnterCombat(Enemy enemy)
    {
        if (enemy == null)
        {
            return;
        }

        if (_combatants.Contains(enemy))
        {
            return;
        }

        bool _wasInCombat = (_combatants.Count == 0)?false:true;

        _combatants.Add(enemy);
        EmitSignal(SignalName.CombatantAdded, enemy);
    }

    public void ExitCombat(Enemy enemy)
    {
        if (enemy == null)
        {
            return;
        }

        if (!(_combatants.Contains(enemy)))
        {
            return;
        }

        _combatants.Remove(enemy);
        EmitSignal(SignalName.CombatantRemoved, enemy);

        if (_combatants.Count == 0)
        {
            EmitSignal(SignalName.CombatEnded);
        }

        _updateCombatState();
    }

    public bool IsInCombat()
    {
        _cleanupCombatants();

        return !(_combatants.Count == 0);
    }

    public List<Enemy> GetCombatants()
    {
        _cleanupCombatants();
        return _combatants;
    }

    public void _cleanupCombatants()
    {
        foreach (Enemy enemy in _combatants.ToList())
        {
            if (!GodotObject.IsInstanceValid(enemy))
            {
                _combatants.Remove(enemy);
            }
        }
    }

    public void _updateCombatState()
    {
        var player = GetTree().GetFirstNodeInGroup("player") as Player;

        if (player == null)
        {
            return;
        }

        player.SetCombatState(!(_combatants.Count == 0));
    }
}
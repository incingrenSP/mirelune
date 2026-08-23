using Godot;

public partial class GameStateManager : Node
{
    public static GameStateManager Instance { get; private set; }
    private enum GameMode
    {
        Gameplay,
        Dialog,
        Paused
    }

    private GameMode _currentMode = GameMode.Gameplay;
    private GameMode _previousMode = GameMode.Gameplay;
    
    public override void _Ready()
    {
        Instance = this;
    }


    public bool IsGameplayActive()
    {
        return (_currentMode == GameMode.Gameplay);
    }

    public bool IsDialogActive()
    {
        return (_currentMode == GameMode.Dialog);
    }

    public bool IsPaused()
    {
        return (_currentMode == GameMode.Paused);
    }

    public void EnterDialog()
    {
        if (_currentMode != GameMode.Gameplay)
        {
            return;
        }
        _currentMode = GameMode.Dialog;
    }

    public void ExitDialog()
    {
        if (_currentMode != GameMode.Dialog)
        {
            return;
        }
        _currentMode = GameMode.Gameplay;
    }

    public bool CanPause()
    {
        if (CombatManager.Instance.IsInCombat())
        {
            return false;
        }

        return (_currentMode == GameMode.Gameplay || _currentMode == GameMode.Dialog);
    }

    public void PauseGame()
    {
        if (!CanPause())
        {
            return;
        }

        _previousMode = _currentMode;
        _currentMode = GameMode.Paused;

        GetTree().Paused = true;
    }

    public void ResumeGame()
    {
        if (_currentMode != GameMode.Paused)
        {
            return;
        }

        GetTree().Paused = false;
        _currentMode = _previousMode;
    }
}
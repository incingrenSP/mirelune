using Godot;
using System.Collections.Generic;

public partial class DialogText : RichTextLabel
{
    [Signal]
    public delegate void PageShown(string pageText);

    private const int CharactersPerSecond = 80;

    private List<string> pages = new();
    private int _currentPage = 0;
    public bool revealing = false;
    private Tween _revealTween;

    public void ShowText(string fullText)
    {
        BbCodeEnabled = true;
        ScrollActive = false;
        FitContent = false;

        pages = Paginate(fullText);
        _currentPage = 0;
        ShowPage(0);
    }

    private List<string> Paginate(string fullText)
    {
        string[] words = fullText.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        List<string> result = new();
        int start = 0;

        while (start < words.Length)
        {
            int fitCount = FindFitLength(words, start);

            result.Add(
                string.Join(" ", words[start..(start + fitCount)])
            );

            start += fitCount;
        }
        return result;
    }

    private int FindFitLength(string[] words, int start)
    {
        int remainingCount = words.Length - start;
        string text = words[start];

        if (GetContentHeight() > Size.Y)
        {
            return 1;
        }

        int lo = 1;
        int hi = remainingCount;

        while (lo < hi)
        {
            int mid = (lo + hi + 1) / 2;
            string candidate = string.Join(
                " ",
                words[start..(start + mide)]
            );
            text = candidate;

            if (GetContentHeight() <= Size.Y)
            {
                lo = mid;
            }
            else
            {
                hi = mid - 1;
            }
        }
        return Mathf.Max(lo, 1);
    }

    private void ShowPage(int index)
    {
        string text = pages[index];
        VisibleRatio = 0.0f;
        revealing = true;

        if (_revealTween != null)
        {
            _revealTween.Kill();
        }

        int charCount = GetTotalCharacterCount();
        float duration = charCount / CharactersPerSecond;

        _revealTween = CreateTween();
        _revealTween.TweenProperty(self, "VisibleRatio", 1.0, duration);
        _revealTween.Finished += () => revealing = false;

        EmitSignal(SignalName.PageShown, pages[index]);
    }

    public void SkipReveal()
    {
        if (_revealTween != null)
        {
            _revealTween.Kill();
        }

        VisibleRatio = 1.0;
        revealing = false;
    }

    public bool AdvancePage()
    {
        _currentPage += 1;
        if (_currentPage < pages.Length)
        {
            ShowPage(_currentPage);
            return true;
        }

        return false;
    }
}
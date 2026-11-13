param(
  [string]$WindowTitle = $env:COPILOT_WINDOW_TITLE
)

if ([string]::IsNullOrWhiteSpace($WindowTitle)) {
  $WindowTitle = "Copilot"
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class OverlayLabel {
    public Rectangle Bounds;
    public string Text = "";
}

public sealed class CopilotOverlayForm : Form {
    public List<OverlayLabel> Labels { get; } = new List<OverlayLabel>();
    private const int WS_EX_TRANSPARENT = 0x20;
    private const int WS_EX_TOOLWINDOW = 0x80;
    private const int WS_EX_NOACTIVATE = 0x8000000;

    public CopilotOverlayForm() {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        BackColor = Color.Magenta;
        TransparencyKey = Color.Magenta;
        DoubleBuffered = true;
        StartPosition = FormStartPosition.Manual;
    }

    protected override CreateParams CreateParams {
        get {
            var parameters = base.CreateParams;
            parameters.ExStyle |= WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
            return parameters;
        }
    }

    protected override bool ShowWithoutActivation {
        get { return true; }
    }

    protected override void OnPaint(PaintEventArgs e) {
        using (var background = new SolidBrush(Color.FromArgb(235, 32, 32, 32)))
        using (var foreground = new SolidBrush(Color.White))
        using (var font = new Font("Microsoft YaHei UI", 9.0f)) {
            foreach (var label in Labels) {
                if (label.Bounds.Width < 2 || label.Bounds.Height < 2) continue;
                e.Graphics.FillRectangle(background, label.Bounds);
                e.Graphics.DrawString(label.Text, font, foreground, label.Bounds,
                    new StringFormat {
                        Alignment = StringAlignment.Near,
                        LineAlignment = StringAlignment.Center,
                        Trimming = StringTrimming.EllipsisCharacter,
                        FormatFlags = StringFormatFlags.NoWrap
                    });
            }
        }
    }
}

public static class WindowLocator {
    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr extraData);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    public static IntPtr Find(string titlePart) {
        IntPtr result = IntPtr.Zero;
        EnumWindows((hWnd, unused) => {
            if (!IsWindowVisible(hWnd)) return true;
            var title = new System.Text.StringBuilder(512);
            GetWindowText(hWnd, title, title.Capacity);
            if (title.ToString().IndexOf(titlePart, StringComparison.OrdinalIgnoreCase) >= 0) {
                result = hWnd;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    public static Rectangle GetBounds(IntPtr hWnd) {
        RECT rect;
        if (!GetWindowRect(hWnd, out rect)) return Rectangle.Empty;
        return Rectangle.FromLTRB(rect.Left, rect.Top, rect.Right, rect.Bottom);
    }
}
"@

$localePath = Join-Path $PSScriptRoot "..\locales\zh-CN.json"
if (-not (Test-Path -LiteralPath $localePath)) {
  throw "Translation file not found: $localePath"
}

$locale = Get-Content -LiteralPath $localePath -Raw -Encoding UTF8 | ConvertFrom-Json
$translations = @{}
$locale.messages.PSObject.Properties | ForEach-Object {
  $translations[$_.Name] = [string]$_.Value
}

function Get-TranslatedLabels {
  param(
    [IntPtr]$Handle,
    [hashtable]$Map
  )

  $result = New-Object System.Collections.Generic.List[OverlayLabel]
  if ($Handle -eq [IntPtr]::Zero) {
    return $result
  }

  try {
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $queue = New-Object System.Collections.Generic.Queue[System.Windows.Automation.AutomationElement]
    $queue.Enqueue($root)
    while ($queue.Count -gt 0) {
      $element = $queue.Dequeue()
      try {
        $name = $element.Current.Name
        if ($name -and $Map.ContainsKey($name)) {
          $rect = $element.Current.BoundingRectangle
          if ($rect.Width -gt 2 -and $rect.Height -gt 2) {
            $label = New-Object OverlayLabel
            $label.Bounds = New-Object System.Drawing.Rectangle -ArgumentList @(
              [int]$rect.X, [int]$rect.Y, [int]$rect.Width, [int]$rect.Height
            )
            $label.Text = $Map[$name]
            $result.Add($label)
          }
        }
        $child = $walker.GetFirstChild($element)
        while ($child) {
          $queue.Enqueue($child)
          $child = $walker.GetNextSibling($child)
        }
      } catch {
        # UI Automation nodes may disappear while the app redraws.
      }
    }
  } catch {
    return $result
  }
  return $result
}

$overlay = New-Object CopilotOverlayForm
$overlay.Show()

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 700
$timer.Add_Tick({
  $handle = [WindowLocator]::Find($WindowTitle)
  if ($handle -eq [IntPtr]::Zero) {
    $overlay.Hide()
    return
  }

  $window = New-Object System.Windows.Forms.NativeWindow
  $window.AssignHandle($handle)
  try {
    $bounds = [WindowLocator]::GetBounds($handle)
    if ($bounds.IsEmpty) {
      $overlay.Hide()
      return
    }
    $overlay.Bounds = $bounds
    $overlay.Labels.Clear()
    foreach ($label in (Get-TranslatedLabels -Handle $handle -Map $translations)) {
      $local = $label.Bounds
      $local.X -= $bounds.X
      $local.Y -= $bounds.Y
      $label.Bounds = $local
      $overlay.Labels.Add($label)
    }
    if (-not $overlay.Visible) {
      $overlay.Show()
    }
    $overlay.Invalidate()
  } finally {
    $window.ReleaseHandle()
  }
})
$timer.Start()

[System.Windows.Forms.Application]::Run($overlay)

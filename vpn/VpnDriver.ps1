param(
    [Parameter(Mandatory = $true)][int]$TargetPid,
    [string]$CredTarget = "vpn.example.com",
    [string]$VpnHost    = "vpn.example.com",
    [string]$Group      = "",
    [int]   $TimeoutSec = 60,
    [string]$LogFile    = ""
)

function Note($m) { if ($LogFile) { try { Add-Content -Path $LogFile -Value ("[driver] " + $m) -Encoding utf8 } catch {} } }

Add-Type -Language CSharp -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public class CredMan {
  [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  static extern bool CredRead(string t, int ty, int f, out IntPtr c);
  [DllImport("advapi32.dll")] static extern void CredFree(IntPtr c);
  [StructLayout(LayoutKind.Sequential)] struct CRED {
    public int Flags; public int Type; public IntPtr TargetName; public IntPtr Comment;
    public long Last; public int BlobSize; public IntPtr Blob; public int Persist;
    public int AttrCount; public IntPtr Attrs; public IntPtr Alias; public IntPtr User; }
  public static string[] Read(string target) {
    IntPtr p; if (!CredRead(target,1,0,out p)) return null;
    var c=(CRED)Marshal.PtrToStructure(p,typeof(CRED));
    string u=c.User!=IntPtr.Zero?Marshal.PtrToStringUni(c.User):"";
    string pw=""; if (c.BlobSize>0) pw=Marshal.PtrToStringUni(c.Blob,c.BlobSize/2);
    CredFree(p); return new string[]{u,pw};
  }
}
'@
$cred = [CredMan]::Read($CredTarget)
if ($null -eq $cred) { Note "cred read failed"; exit 2 }
$user = $cred[0]; $pass = $cred[1]
if ([string]::IsNullOrEmpty($pass)) { Note "empty password"; exit 2 }

Add-Type -Language CSharp -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
using System.Collections.Generic;
public class Con {
  [DllImport("kernel32.dll")] static extern bool FreeConsole();
  [DllImport("kernel32.dll")] static extern bool AttachConsole(uint pid);
  [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    static extern IntPtr CreateFileW(string n, uint a, uint s, IntPtr sa, uint d, uint f, IntPtr t);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
  [DllImport("kernel32.dll")] static extern bool WriteConsoleInputW(IntPtr h, INPUT_RECORD[] b, uint len, out uint w);
  [DllImport("kernel32.dll")] static extern bool GetConsoleScreenBufferInfo(IntPtr h, out CSBI info);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
    static extern bool ReadConsoleOutputCharacterW(IntPtr h, [Out] char[] buf, uint len, COORD coord, out uint read);

  const uint GR=0x80000000, GW=0x40000000, SR=1, SW=2, OPEN=3;
  [StructLayout(LayoutKind.Sequential)] public struct COORD { public short X, Y; }
  [StructLayout(LayoutKind.Sequential)] public struct SRECT { public short L,T,R,B; }
  [StructLayout(LayoutKind.Sequential)] public struct CSBI {
    public COORD size; public COORD cursor; public ushort attr; public SRECT win; public COORD max; }
  [StructLayout(LayoutKind.Sequential)] struct KEY {
    public int down; public ushort rep; public ushort vk; public ushort sc; public ushort ch; public uint ctrl; }
  [StructLayout(LayoutKind.Explicit)] struct INPUT_RECORD {
    [FieldOffset(0)] public ushort type; [FieldOffset(4)] public KEY key; }

  static IntPtr hIn = IntPtr.Zero, hOut = IntPtr.Zero;

  public static bool Attach(uint pid) {
    FreeConsole();
    if (!AttachConsole(pid)) return false;
    hIn  = CreateFileW("CONIN$",  GR|GW, SR|SW, IntPtr.Zero, OPEN, 0, IntPtr.Zero);
    hOut = CreateFileW("CONOUT$", GR|GW, SR|SW, IntPtr.Zero, OPEN, 0, IntPtr.Zero);
    return hIn.ToInt64()!=-1 && hOut.ToInt64()!=-1;
  }
  public static void Detach() {
    if (hIn !=IntPtr.Zero) CloseHandle(hIn);
    if (hOut!=IntPtr.Zero) CloseHandle(hOut);
    FreeConsole();
  }
  public static string ReadTail(int rows) {
    CSBI info;
    if (!GetConsoleScreenBufferInfo(hOut, out info)) return "";
    int width = info.size.X; int curY = info.cursor.Y;
    int startY = curY - rows; if (startY < 0) startY = 0;
    int count = (curY - startY + 1) * width;
    if (count <= 0 || width <= 0) return "";
    char[] buf = new char[count]; uint read;
    COORD c; c.X = 0; c.Y = (short)startY;
    if (!ReadConsoleOutputCharacterW(hOut, buf, (uint)count, c, out read)) return "";
    var sb = new StringBuilder();
    for (int i=0; i<read; i++) { sb.Append(buf[i]); if ((i+1)%width==0) sb.Append('\n'); }
    return sb.ToString();
  }
  static INPUT_RECORD Rec(char ch, bool down) {
    var r=new INPUT_RECORD(); r.type=1; r.key.down=down?1:0; r.key.rep=1;
    r.key.vk=0; r.key.sc=0; r.key.ch=(ushort)ch; r.key.ctrl=0; return r; }
  public static void Send(string s) {
    var recs = new List<INPUT_RECORD>();
    foreach (char ch in s) { recs.Add(Rec(ch,true)); recs.Add(Rec(ch,false)); }
    recs.Add(Rec('\r',true)); recs.Add(Rec('\r',false));
    var arr = recs.ToArray(); uint w;
    WriteConsoleInputW(hIn, arr, (uint)arr.Length, out w);
  }
}
'@

if (-not [Con]::Attach([uint32]$TargetPid)) { Note "attach failed"; exit 3 }

$result = 1
try {
    $sentConnect=$false; $sentY=$false; $sentGroup=$false; $sentUser=$false; $sentPass=$false
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $screen = [Con]::ReadTail(35)

        if ($screen -match 'state:\s*Connected' -or $screen -match 'Connected to') {
            $result = 0; Note "connected"
            try { [Con]::Send("quit"); Start-Sleep -Milliseconds 400; Note "sent quit (graceful exit)" } catch { Note "quit send failed: $_" }
            break
        }
        if ($screen -match '(?i)login failed' -or $screen -match '(?i)connection attempt has failed') { Note "failed prompt seen"; $result = 1; break }

        if (-not $sentConnect -and $screen -match 'VPN>') {
            [Con]::Send("connect $VpnHost"); $sentConnect=$true; Note "sent connect"
        }
        elseif ($sentConnect -and -not $sentY -and $screen -match '(?i)Connect Anyway') {
            [Con]::Send("y"); $sentY=$true; Note "sent y (cert)"
        }
        elseif ($sentY -and -not $sentGroup -and $screen -match 'Group:') {
            [Con]::Send($Group); $sentGroup=$true; Note "sent group '$Group'"
        }
        elseif ($sentGroup -and -not $sentUser -and $screen -match 'Username:') {
            [Con]::Send($user); $sentUser=$true; Note "sent username"
        }
        elseif ($sentUser -and -not $sentPass -and $screen -match 'Password:') {
            [Con]::Send($pass); $sentPass=$true; Note "sent password"
        }
        Start-Sleep -Milliseconds 250
    }
} finally { [Con]::Detach() }

Note "exit $result"
exit $result

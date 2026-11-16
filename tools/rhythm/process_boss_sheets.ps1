param(
    [Parameter(Mandatory=$true)][string]$IdleSheet,
    [Parameter(Mandatory=$true)][string]$ThrowSheet,
    [Parameter(Mandatory=$true)][string]$HurtSheet,
    [Parameter(Mandatory=$true)][string]$DefeatSheet
)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.IO;

public static class BossSheetProcessor {
    static bool Green(byte r,byte g,byte b) { return g>=70 && g>r+10 && g>b+8; }

    static void KeyGreen(Bitmap bmp) {
        var data=bmp.LockBits(new Rectangle(0,0,bmp.Width,bmp.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
        int stride=Math.Abs(data.Stride); byte[] px=new byte[stride*bmp.Height]; Marshal.Copy(data.Scan0,px,0,px.Length);
        for(int y=0;y<bmp.Height;y++) {
            int row=data.Stride>=0?y*stride:(bmp.Height-1-y)*stride;
            for(int x=0;x<bmp.Width;x++) { int i=row+x*4; if(Green(px[i+2],px[i+1],px[i])) px[i]=px[i+1]=px[i+2]=px[i+3]=0; }
        }
        Marshal.Copy(px,0,data.Scan0,px.Length); bmp.UnlockBits(data);
    }

    static void CleanSaved(string path) {
        byte[] output;
        using(var input=new MemoryStream(File.ReadAllBytes(path))) using(var saved=new Bitmap(input))
        using(var clean=new Bitmap(saved.Width,saved.Height,PixelFormat.Format32bppArgb)) {
            using(var g=Graphics.FromImage(clean)) { g.Clear(Color.Transparent); g.DrawImageUnscaled(saved,0,0); }
            KeyGreen(clean);
            using(var stream=new MemoryStream()) { clean.Save(stream,ImageFormat.Png); output=stream.ToArray(); }
        }
        File.WriteAllBytes(path,output);
    }

    static string Validate(string path) {
        using(var bmp=new Bitmap(path)) {
            if(bmp.Width!=768||bmp.Height!=768) throw new Exception("Bad boss frame dimensions: "+path);
            var data=bmp.LockBits(new Rectangle(0,0,768,768),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
            int stride=Math.Abs(data.Stride); byte[] px=new byte[stride*768]; Marshal.Copy(data.Scan0,px,0,px.Length); bmp.UnlockBits(data);
            int green=0; for(int y=0;y<768;y++) for(int x=0;x<768;x++) { int i=y*stride+x*4; if(px[i+3]>0&&Green(px[i+2],px[i+1],px[i])) green++; }
            if(green>0) throw new Exception("Visible chroma pixels remain in "+path+": "+green);
            return Path.GetFileName(path)+" 768x768, visible chroma pixels=0";
        }
    }

    public static void SaveCell(string sourcePath,int columns,int rows,int index,int inset,string targetPath) {
        using(var source=new Bitmap(sourcePath)) {
            int x0=(int)Math.Round((double)(index%columns)*source.Width/columns,MidpointRounding.AwayFromZero);
            int x1=(int)Math.Round((double)(index%columns+1)*source.Width/columns,MidpointRounding.AwayFromZero);
            int y0=(int)Math.Round((double)(index/columns)*source.Height/rows,MidpointRounding.AwayFromZero);
            int y1=(int)Math.Round((double)(index/columns+1)*source.Height/rows,MidpointRounding.AwayFromZero);
            int sx=x0+inset,sy=y0+inset,sw=x1-x0-2*inset,sh=y1-y0-2*inset;
            if(sw<=0||sh<=0) throw new Exception("Inset removes cell: "+sourcePath);
            using(var crop=source.Clone(new Rectangle(sx,sy,sw,sh),PixelFormat.Format32bppArgb))
            using(var output=new Bitmap(768,768,PixelFormat.Format32bppArgb)) {
                KeyGreen(crop);
                using(var g=Graphics.FromImage(output)) {
                    g.Clear(Color.Transparent); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality; g.DrawImage(crop,new Rectangle(0,0,768,768));
                }
                KeyGreen(output); output.Save(targetPath,ImageFormat.Png);
            }
        }
        CleanSaved(targetPath); Console.WriteLine(Validate(targetPath));
    }
}
'@

$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$bossRoot=Join-Path $root 'assets/rhythm/rh_boss_eclipse'
foreach($anim in @('idle','throw','hurt','defeat')) { New-Item -ItemType Directory -Force -Path (Join-Path $bossRoot $anim) | Out-Null }
$idle=(Resolve-Path $IdleSheet).Path; $throw=(Resolve-Path $ThrowSheet).Path
$hurt=(Resolve-Path $HurtSheet).Path; $defeat=(Resolve-Path $DefeatSheet).Path

# Repeat the first cell at the end to close the 8-frame idle loop exactly.
$idleCells=@(0,1,2,3,4,5,6,0)
for($i=0;$i -lt 8;$i++) { [BossSheetProcessor]::SaveCell($idle,4,2,$idleCells[$i],3,(Join-Path $bossRoot ('idle/rh_boss_eclipse_idle_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 6;$i++) { [BossSheetProcessor]::SaveCell($throw,3,2,$i,1,(Join-Path $bossRoot ('throw/rh_boss_eclipse_throw_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 3;$i++) { [BossSheetProcessor]::SaveCell($hurt,3,1,$i,0,(Join-Path $bossRoot ('hurt/rh_boss_eclipse_hurt_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 10;$i++) { [BossSheetProcessor]::SaveCell($defeat,5,2,$i,2,(Join-Path $bossRoot ('defeat/rh_boss_eclipse_defeat_{0:D3}.png' -f $i))) }
Write-Output 'Exported idle 8, throw 6, hurt 3, defeat 10 at 768x768.'

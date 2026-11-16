param(
    [Parameter(Mandatory=$true)][string]$IdleSheet,
    [Parameter(Mandatory=$true)][string]$HitSheet,
    [Parameter(Mandatory=$true)][string]$CrackSheet,
    [Parameter(Mandatory=$true)][string]$BurstSheet,
    [Parameter(Mandatory=$true)][string]$EscapeSheet
)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class DrumSheetProcessor {
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
        string temp=path+".clean.png";
        using(var saved=new Bitmap(path)) using(var clean=new Bitmap(saved.Width,saved.Height,PixelFormat.Format32bppArgb)) {
            using(var g=Graphics.FromImage(clean)) { g.Clear(Color.Transparent); g.DrawImageUnscaled(saved,0,0); }
            KeyGreen(clean); clean.Save(temp,ImageFormat.Png);
        }
        System.IO.File.Delete(path); System.IO.File.Move(temp,path);
    }

    static string Validate(string path) {
        using(var bmp=new Bitmap(path)) {
            if(bmp.Width!=512||bmp.Height!=512) throw new Exception("Bad frame size: "+path);
            var data=bmp.LockBits(new Rectangle(0,0,512,512),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
            int stride=Math.Abs(data.Stride); byte[] px=new byte[stride*512]; Marshal.Copy(data.Scan0,px,0,px.Length); bmp.UnlockBits(data);
            int green=0; for(int y=0;y<512;y++) for(int x=0;x<512;x++) { int i=y*stride+x*4; if(px[i+3]>0&&Green(px[i+2],px[i+1],px[i])) green++; }
            if(green>0) throw new Exception("Visible chroma pixels remain in "+path+": "+green);
            return System.IO.Path.GetFileName(path)+" 512x512, visible chroma pixels=0";
        }
    }

    public static void SaveCell(string sourcePath,int columns,int rows,int index,int inset,string targetPath) {
        using(var source=new Bitmap(sourcePath)) {
            if(source.Width%columns!=0 || source.Height%rows!=0) throw new Exception("Sheet does not divide evenly: "+sourcePath);
            int cw=source.Width/columns,ch=source.Height/rows;
            if(index<0 || index>=columns*rows) throw new Exception("Cell index out of range.");
            int sx=(index%columns)*cw+inset, sy=(index/columns)*ch+inset;
            int sw=cw-2*inset, sh=ch-2*inset;
            if(sw<=0||sh<=0) throw new Exception("Inset removes the entire cell.");
            using(var crop=source.Clone(new Rectangle(sx,sy,sw,sh),PixelFormat.Format32bppArgb))
            using(var output=new Bitmap(512,512,PixelFormat.Format32bppArgb)) {
                KeyGreen(crop);
                using(var g=Graphics.FromImage(output)) {
                    g.Clear(Color.Transparent); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality; g.DrawImage(crop,new Rectangle(0,0,512,512));
                }
                KeyGreen(output); output.Save(targetPath,ImageFormat.Png);
            }
        }
        CleanSaved(targetPath);
        Console.WriteLine(Validate(targetPath));
    }
}
'@

$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$rhythmRoot=Join-Path $root 'assets/rhythm/rh_drum'
foreach($anim in @('idle','hit','crack','burst','escape')) { New-Item -ItemType Directory -Force -Path (Join-Path $rhythmRoot $anim) | Out-Null }
$idle=(Resolve-Path $IdleSheet).Path; $hit=(Resolve-Path $HitSheet).Path; $crack=(Resolve-Path $CrackSheet).Path
$burst=(Resolve-Path $BurstSheet).Path; $escape=(Resolve-Path $EscapeSheet).Path

# Reuse the identical first pose as the last idle cell so the loop closes exactly.
$idleCells=@(0,1,2,0)
for($i=0;$i -lt 4;$i++) { [DrumSheetProcessor]::SaveCell($idle,2,2,$idleCells[$i],3,(Join-Path $rhythmRoot ('idle/rh_drum_idle_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 3;$i++) { [DrumSheetProcessor]::SaveCell($hit,3,1,$i,0,(Join-Path $rhythmRoot ('hit/rh_drum_hit_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 3;$i++) { [DrumSheetProcessor]::SaveCell($crack,3,1,$i,0,(Join-Path $rhythmRoot ('crack/rh_drum_crack_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 6;$i++) { [DrumSheetProcessor]::SaveCell($burst,3,2,$i,3,(Join-Path $rhythmRoot ('burst/rh_drum_burst_{0:D3}.png' -f $i))) }
for($i=0;$i -lt 6;$i++) { [DrumSheetProcessor]::SaveCell($escape,3,2,$i,3,(Join-Path $rhythmRoot ('escape/rh_drum_escape_{0:D3}.png' -f $i))) }
Write-Output 'Exported idle 4, hit 3, crack 3, burst 6, escape 6 at 512x512.'

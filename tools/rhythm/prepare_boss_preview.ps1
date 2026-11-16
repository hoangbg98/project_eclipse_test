param([Parameter(Mandatory=$true)][string]$SourceImage)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class BossPreviewProcessor {
    static void FlattenGreen(Bitmap bmp) {
        var rect=new Rectangle(0,0,bmp.Width,bmp.Height);
        var data=bmp.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
        int stride=Math.Abs(data.Stride); byte[] bytes=new byte[stride*bmp.Height]; Marshal.Copy(data.Scan0,bytes,0,bytes.Length);
        for(int y=0;y<bmp.Height;y++) {
            int row=data.Stride>=0?y*stride:(bmp.Height-1-y)*stride;
            for(int x=0;x<bmp.Width;x++) {
                int i=row+x*4; byte b=bytes[i],g=bytes[i+1],r=bytes[i+2];
                if(g>r+40&&g>b+30&&g>100) { bytes[i]=64; bytes[i+1]=177; bytes[i+2]=0; bytes[i+3]=255; }
            }
        }
        Marshal.Copy(bytes,0,data.Scan0,bytes.Length); bmp.UnlockBits(data);
    }
    public static void Prepare(string sourcePath,string targetPath) {
        using(var input=new Bitmap(sourcePath))
        using(var normalized=new Bitmap(input.Width,input.Height,PixelFormat.Format32bppArgb)) {
            using(var g=Graphics.FromImage(normalized)) { g.CompositingMode=CompositingMode.SourceCopy; g.DrawImage(input,0,0,input.Width,input.Height); }
            FlattenGreen(normalized);
            using(var canvas=new Bitmap(768,768,PixelFormat.Format32bppArgb)) {
                using(var g=Graphics.FromImage(canvas)) {
                    g.Clear(Color.FromArgb(0,177,64)); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality;
                    double scale=Math.Min(768.0/input.Width,768.0/input.Height);
                    int w=(int)Math.Round(input.Width*scale),h=(int)Math.Round(input.Height*scale);
                    g.DrawImage(normalized,new Rectangle((768-w)/2,(768-h)/2,w,h));
                }
                FlattenGreen(canvas); canvas.Save(targetPath,ImageFormat.Png);
            }
        }
    }
}
'@

$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source=(Resolve-Path $SourceImage).Path
$target=Join-Path $root 'assets/rhythm/_preview/rh_boss_eclipse_original_preview.png'
[BossPreviewProcessor]::Prepare($source,$target)
Write-Output 'Saved 768x768 eclipse boss preview with a uniform #00B140 background.'

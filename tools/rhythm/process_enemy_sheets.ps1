param(
    [Parameter(Mandatory=$true)][string]$EnemyId,
    [Parameter(Mandatory=$true)][string]$FirstSheet,
    [Parameter(Mandatory=$true)][string]$FirstAnim,
    [Parameter(Mandatory=$true)][int]$FirstCount,
    [string]$FirstOutputFolder,
    [int]$FirstInset = 0,
    [Parameter(Mandatory=$true)][string]$SecondSheet,
    [Parameter(Mandatory=$true)][string]$SecondAnim,
    [Parameter(Mandatory=$true)][int]$SecondCount,
    [string]$SecondOutputFolder,
    [int]$SecondInset = 0,
    [string]$ChainImage
)

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class EnemySheetProcessor {
    static byte Clamp(double v) { return (byte)Math.Max(0, Math.Min(255, Math.Round(v))); }
    public static void Process(string path, string enemyId, string anim, int count, int inset, string folder) {
        using (var input = new Bitmap(path))
        using (var normalized = new Bitmap(input.Width, input.Height, PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(normalized)) g.DrawImage(input, 0, 0, input.Width, input.Height);
            if (normalized.Width % 3 != 0 || normalized.Height % 2 != 0) throw new Exception("Not a 3x2 sheet: " + path);
            int cw = normalized.Width / 3, ch = normalized.Height / 2;
            int sw=cw-2*inset, sh=ch-2*inset;
            if (inset<0 || sw<1 || sh<1) throw new Exception("Invalid cell inset " + inset);
            Console.WriteLine(anim + " sheet " + normalized.Width + "x" + normalized.Height + ", cells " + cw + "x" + ch);
            var rect = new Rectangle(0, 0, normalized.Width, normalized.Height);
            var data = normalized.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            byte[] src = new byte[data.Stride * data.Height];
            Marshal.Copy(data.Scan0, src, 0, src.Length);
            normalized.UnlockBits(data);
            for (int i = 0; i < count; i++) {
                int ox = (i % 3) * cw, oy = (i / 3) * ch;
                Color[] corners = { normalized.GetPixel(ox+inset,oy+inset), normalized.GetPixel(ox+cw-inset-1,oy+inset), normalized.GetPixel(ox+inset,oy+ch-inset-1), normalized.GetPixel(ox+cw-inset-1,oy+ch-inset-1) };
                double keyR=0, keyG=0, keyB=0;
                foreach(Color corner in corners) { keyR+=corner.R/4.0; keyG+=corner.G/4.0; keyB+=corner.B/4.0; }
                Console.WriteLine("Frame "+i+" sampled key #"+((int)Math.Round(keyR)).ToString("X2")+((int)Math.Round(keyG)).ToString("X2")+((int)Math.Round(keyB)).ToString("X2"));
                using (var cell = new Bitmap(sw, sh, PixelFormat.Format32bppArgb)) {
                    var cd = cell.LockBits(new Rectangle(0,0,sw,sh), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                    byte[] pixels = new byte[cd.Stride * sh];
                    for (int y=0; y<sh; y++) for (int x=0; x<sw; x++) {
                        int si=(oy+inset+y)*data.Stride+(ox+inset+x)*4, di=y*cd.Stride+x*4;
                        double b=src[si], g=src[si+1], r=src[si+2];
                        double db=b-keyB, dg=g-keyG, dr=r-keyR;
                        double d=Math.Sqrt(dr*dr+dg*dg+db*db);
                        if ((g > r + 15 && g > b + 15) || d <= 18) { pixels[di]=pixels[di+1]=pixels[di+2]=pixels[di+3]=0; }
                        else if (d < 80) {
                            double a=(d-18)/62.0;
                            pixels[di]=Clamp((b-keyB*(1-a))/a);
                            pixels[di+1]=Clamp((g-keyG*(1-a))/a);
                            pixels[di+2]=Clamp((r-keyR*(1-a))/a);
                            pixels[di+3]=Clamp(255*a);
                        } else {
                            pixels[di]=src[si]; pixels[di+1]=src[si+1]; pixels[di+2]=src[si+2]; pixels[di+3]=src[si+3];
                        }
                    }
                    Marshal.Copy(pixels,0,cd.Scan0,pixels.Length); cell.UnlockBits(cd);
                    using (var output = new Bitmap(256,256,PixelFormat.Format32bppArgb)) {
                        using (var g = Graphics.FromImage(output)) {
                            g.Clear(Color.Transparent); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                            g.PixelOffsetMode=PixelOffsetMode.HighQuality; g.CompositingMode=CompositingMode.SourceCopy;
                            g.DrawImage(cell,new Rectangle(0,0,256,256),new Rectangle(0,0,sw,sh),GraphicsUnit.Pixel);
                        }
                        string file=System.IO.Path.Combine(folder,String.Format("{0}_{1}_{2:D3}.png",enemyId,anim,i));
                        int green=0; var od=output.LockBits(new Rectangle(0,0,256,256),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
                        byte[] op=new byte[od.Stride*od.Height]; Marshal.Copy(od.Scan0,op,0,op.Length); output.UnlockBits(od);
                        for(int y0=0;y0<256;y0++) for(int x=0;x<256;x++) {
                            int q=y0*od.Stride+x*4;
                            if(op[q+3]>0 && op[q+1]>op[q+2]+15 && op[q+1]>op[q]+15) op[q]=op[q+1]=op[q+2]=op[q+3]=0;
                        }
                        od=output.LockBits(new Rectangle(0,0,256,256),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb); Marshal.Copy(op,0,od.Scan0,op.Length); output.UnlockBits(od);
                        output.Save(file,ImageFormat.Png);
                        od=output.LockBits(new Rectangle(0,0,256,256),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb); Marshal.Copy(od.Scan0,op,0,op.Length); output.UnlockBits(od);
                        for(int y0=0;y0<256;y0++) for(int x=0;x<256;x++) { int q=y0*od.Stride+x*4; if(op[q+3]>16 && op[q+1]>op[q+2]+15 && op[q+1]>op[q]+15) green++; }
                        Console.WriteLine(System.IO.Path.GetFileName(file)+": 256x256; opaque green-dominant pixels="+green);
                    }
                }
            }
        }
    }
    public static void ProcessChain(string path, string target) {
        using (var input = new Bitmap(path))
        using (var normalized = new Bitmap(input.Width,input.Height,PixelFormat.Format32bppArgb)) {
            using (var g=Graphics.FromImage(normalized)) { g.Clear(Color.Transparent); g.CompositingMode=CompositingMode.SourceCopy; g.DrawImage(input,0,0,input.Width,input.Height); }
            var data=normalized.LockBits(new Rectangle(0,0,normalized.Width,normalized.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
            byte[] src=new byte[data.Stride*data.Height]; Marshal.Copy(data.Scan0,src,0,src.Length); normalized.UnlockBits(data);
            int minX=normalized.Width,minY=normalized.Height,maxX=-1,maxY=-1;
            for(int y=0;y<normalized.Height;y++) for(int x=0;x<normalized.Width;x++) if(src[y*data.Stride+x*4+3]>16) { minX=Math.Min(minX,x); minY=Math.Min(minY,y); maxX=Math.Max(maxX,x); maxY=Math.Max(maxY,y); }
            if(maxX<minX||maxY<minY) throw new Exception("Chain image has no visible pixels");
            var bounds=new Rectangle(minX,minY,maxX-minX+1,maxY-minY+1);
            using(var output=new Bitmap(64,256,PixelFormat.Format32bppArgb)) {
                using(var g=Graphics.FromImage(output)) { g.Clear(Color.Transparent); g.CompositingMode=CompositingMode.SourceCopy; g.InterpolationMode=InterpolationMode.HighQualityBicubic; g.PixelOffsetMode=PixelOffsetMode.HighQuality; g.DrawImage(normalized,new Rectangle(0,0,64,256),bounds,GraphicsUnit.Pixel); }
                output.Save(target,ImageFormat.Png);
            }
            Console.WriteLine("rh_twin_chain.png: 64x256, alpha-trimmed source bounds="+bounds.ToString());
        }
    }
}
'@

$firstRelative = if ([string]::IsNullOrWhiteSpace($FirstOutputFolder)) { "$EnemyId/$FirstAnim" } else { $FirstOutputFolder }
$secondRelative = if ([string]::IsNullOrWhiteSpace($SecondOutputFolder)) { "$EnemyId/$SecondAnim" } else { $SecondOutputFolder }
$firstDir = Join-Path $PWD ("assets/rhythm/{0}" -f $firstRelative)
$secondDir = Join-Path $PWD ("assets/rhythm/{0}" -f $secondRelative)
[System.IO.Directory]::CreateDirectory($firstDir) | Out-Null
[System.IO.Directory]::CreateDirectory($secondDir) | Out-Null
[EnemySheetProcessor]::Process($FirstSheet, $EnemyId, $FirstAnim, $FirstCount, $FirstInset, $firstDir)
[EnemySheetProcessor]::Process($SecondSheet, $EnemyId, $SecondAnim, $SecondCount, $SecondInset, $secondDir)
if (-not [string]::IsNullOrWhiteSpace($ChainImage)) {
    [EnemySheetProcessor]::ProcessChain($ChainImage, (Join-Path $PWD 'assets/rhythm/rh_twin_chain.png'))
}

param(
    [Parameter(Mandatory=$true)][string]$FlySheet,
    [Parameter(Mandatory=$true)][string]$DieSheet
)

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies ([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class BatSheetProcessor {
    static byte Clamp(double v) { return (byte)Math.Max(0, Math.Min(255, Math.Round(v))); }
    public static void Process(string path, string anim, int count, string folder) {
        using (var input = new Bitmap(path))
        using (var normalized = new Bitmap(input.Width, input.Height, PixelFormat.Format32bppArgb)) {
            using (var g = Graphics.FromImage(normalized)) g.DrawImage(input, 0, 0, input.Width, input.Height);
            if (normalized.Width % 3 != 0 || normalized.Height % 2 != 0) throw new Exception("Not a 3x2 sheet: " + path);
            int cw = normalized.Width / 3, ch = normalized.Height / 2;
            Console.WriteLine(anim + " sheet " + normalized.Width + "x" + normalized.Height + ", cells " + cw + "x" + ch);
            var rect = new Rectangle(0, 0, normalized.Width, normalized.Height);
            var data = normalized.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            byte[] src = new byte[data.Stride * data.Height];
            Marshal.Copy(data.Scan0, src, 0, src.Length);
            normalized.UnlockBits(data);
            for (int i = 0; i < count; i++) {
                int ox = (i % 3) * cw, oy = (i / 3) * ch;
                Color[] corners = { normalized.GetPixel(ox,oy), normalized.GetPixel(ox+cw-1,oy), normalized.GetPixel(ox,oy+ch-1), normalized.GetPixel(ox+cw-1,oy+ch-1) };
                double keyR=0, keyG=0, keyB=0;
                foreach(Color corner in corners) { keyR+=corner.R/4.0; keyG+=corner.G/4.0; keyB+=corner.B/4.0; }
                Console.WriteLine("Frame "+i+" sampled key #"+((int)Math.Round(keyR)).ToString("X2")+((int)Math.Round(keyG)).ToString("X2")+((int)Math.Round(keyB)).ToString("X2"));
                using (var cell = new Bitmap(cw, ch, PixelFormat.Format32bppArgb)) {
                    var cd = cell.LockBits(new Rectangle(0,0,cw,ch), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
                    byte[] pixels = new byte[cd.Stride * ch];
                    for (int y=0; y<ch; y++) for (int x=0; x<cw; x++) {
                        int si=(oy+y)*data.Stride+(ox+x)*4, di=y*cd.Stride+x*4;
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
                            g.DrawImage(cell,new Rectangle(0,0,256,256),new Rectangle(0,0,cw,ch),GraphicsUnit.Pixel);
                        }
                        string file=System.IO.Path.Combine(folder,String.Format("rh_bat_{0}_{1:D3}.png",anim,i));
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
}
'@

$flyDir = Join-Path $PWD 'assets/rhythm/rh_bat/fly'
$dieDir = Join-Path $PWD 'assets/rhythm/rh_bat/die'
[System.IO.Directory]::CreateDirectory($flyDir) | Out-Null
[System.IO.Directory]::CreateDirectory($dieDir) | Out-Null
[BatSheetProcessor]::Process($FlySheet, 'fly', 6, $flyDir)
[BatSheetProcessor]::Process($DieSheet, 'die', 5, $dieDir)

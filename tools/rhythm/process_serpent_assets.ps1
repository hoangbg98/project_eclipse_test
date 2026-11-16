param(
    [Parameter(Mandatory = $true)][string]$IdleSheet,
    [Parameter(Mandatory = $true)][string]$BiteSheet,
    [Parameter(Mandatory = $true)][string]$BodyImage,
    [Parameter(Mandatory = $true)][string]$TailImage
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class SerpentAssetProcessor {
    static bool Green(byte r, byte g, byte b) { return g >= 70 && g > r + 10 && g > b + 8; }

    static byte[] Pixels(Bitmap bmp) {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try {
            int stride = Math.Abs(data.Stride);
            byte[] bytes = new byte[stride * bmp.Height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
            if (data.Stride < 0) {
                byte[] normalized = new byte[bytes.Length];
                for (int y = 0; y < bmp.Height; y++)
                    Buffer.BlockCopy(bytes, (bmp.Height - 1 - y) * stride, normalized, y * stride, stride);
                return normalized;
            }
            return bytes;
        } finally { bmp.UnlockBits(data); }
    }

    static void KeyGreen(Bitmap bmp) {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        try {
            int stride = Math.Abs(data.Stride);
            byte[] bytes = new byte[stride * bmp.Height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
            for (int y = 0; y < bmp.Height; y++) {
                int row = data.Stride >= 0 ? y * stride : (bmp.Height - 1 - y) * stride;
                for (int x = 0; x < bmp.Width; x++) {
                    int i = row + x * 4;
                    if (Green(bytes[i + 2], bytes[i + 1], bytes[i])) {
                        bytes[i] = 0; bytes[i + 1] = 0; bytes[i + 2] = 0; bytes[i + 3] = 0;
                    }
                }
            }
            Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
        } finally { bmp.UnlockBits(data); }
    }

    static void CleanSaved(string path) {
        string temp=path+".clean.png";
        using (var saved=new Bitmap(path)) {
            using (var normalized=new Bitmap(saved.Width,saved.Height,PixelFormat.Format32bppArgb))
            using (var g=Graphics.FromImage(normalized)) {
                g.Clear(Color.Transparent); g.DrawImageUnscaled(saved,0,0); KeyGreen(normalized);
                normalized.Save(temp,ImageFormat.Png);
            }
        }
        System.IO.File.Delete(path); System.IO.File.Move(temp,path);
    }

    static Rectangle Bounds(Bitmap src, int cellX, int cellY, int cellW, int cellH) {
        using (var cell = new Bitmap(cellW, cellH, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(cell)) {
            g.DrawImage(src, new Rectangle(0,0,cellW,cellH), new Rectangle(cellX,cellY,cellW,cellH), GraphicsUnit.Pixel);
            var px = Pixels(cell);
            int left=cellW, top=cellH, right=-1, bottom=-1, stride=cellW*4;
            for (int y=0; y<cellH; y++) for (int x=0; x<cellW; x++) {
                int i=y*stride+x*4;
                if (!Green(px[i+2],px[i+1],px[i])) {
                    if (x<left) left=x; if (x>right) right=x;
                    if (y<top) top=y; if (y>bottom) bottom=y;
                }
            }
            if (right<left || bottom<top) throw new InvalidOperationException("No subject found in sprite cell.");
            left=Math.Max(0,left-4); top=Math.Max(0,top-4);
            right=Math.Min(cellW-1,right+4); bottom=Math.Min(cellH-1,bottom+4);
            return new Rectangle(cellX+left,cellY+top,right-left+1,bottom-top+1);
        }
    }

    static Color Mix(Color a, Color b, double t) {
        return Color.FromArgb((int)Math.Round(a.A*(1-t)+b.A*t),
                              (int)Math.Round(a.R*(1-t)+b.R*t),
                              (int)Math.Round(a.G*(1-t)+b.G*t),
                              (int)Math.Round(a.B*(1-t)+b.B*t));
    }

    static void TileSeamless(Bitmap bmp) {
        const int fade=8;
        for (int y=0; y<bmp.Height; y++) for (int d=0; d<fade; d++) {
            Color left=bmp.GetPixel(d,y), right=bmp.GetPixel(bmp.Width-1-d,y);
            Color average=Mix(left,right,0.5);
            double amount=1.0-(double)d/fade;
            bmp.SetPixel(d,y,Mix(left,average,amount));
            bmp.SetPixel(bmp.Width-1-d,y,Mix(right,average,amount));
        }
    }

    public static void SaveFrame(string input, int cellIndex, string output, int bobY, double scale) {
        using (var src = new Bitmap(input)) {
            int cw=src.Width/2, ch=src.Height/2, cx=(cellIndex%2)*cw, cy=(cellIndex/2)*ch;
            var bounds=Bounds(src,cx,cy,cw,ch);
            using (var crop=src.Clone(bounds,PixelFormat.Format32bppArgb))
            using (var canvas=new Bitmap(256,256,PixelFormat.Format32bppArgb)) {
                KeyGreen(crop);
                using (var g=Graphics.FromImage(canvas)) {
                    g.Clear(Color.Transparent); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality;
                    double fit=Math.Min(224.0/crop.Width,224.0/crop.Height)*scale;
                    int w=(int)Math.Round(crop.Width*fit), h=(int)Math.Round(crop.Height*fit);
                    int x=(int)Math.Round((256-w)/2.0), y=(int)Math.Round((256-h)/2.0)+bobY;
                    g.DrawImage(crop,new Rectangle(x,y,w,h));
                }
                KeyGreen(canvas);
                canvas.Save(output,ImageFormat.Png);
            }
            CleanSaved(output);
        }
    }

    public static void SaveStatic(string input, string output, int width, int height, bool fitSubject) {
        using (var src = new Bitmap(input)) {
            Rectangle bounds = new Rectangle(0,0,src.Width,src.Height);
            if (fitSubject) bounds=Bounds(src,0,0,src.Width,src.Height);
            using (var crop=src.Clone(bounds,PixelFormat.Format32bppArgb))
            using (var canvas=new Bitmap(width,height,PixelFormat.Format32bppArgb)) {
                KeyGreen(crop);
                using (var g=Graphics.FromImage(canvas)) {
                    g.Clear(Color.Transparent); g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    double scale=Math.Min(width/(double)crop.Width,height/(double)crop.Height);
                    int w=(int)Math.Round(crop.Width*scale), h=(int)Math.Round(crop.Height*scale);
                    var dest=new Rectangle((int)Math.Floor((width-w)/2.0),(int)Math.Floor((height-h)/2.0),w,h);
                    g.DrawImage(crop,dest);
                }
                KeyGreen(canvas);
                if (!fitSubject) TileSeamless(canvas);
                canvas.Save(output,ImageFormat.Png);
            }
            CleanSaved(output);
        }
    }
}
'@

$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$idlePath = (Resolve-Path $IdleSheet).Path
$bitePath = (Resolve-Path $BiteSheet).Path
$bodyPath = (Resolve-Path $BodyImage).Path
$tailPath = (Resolve-Path $TailImage).Path
$idleDir = Join-Path $root 'assets/rhythm/rh_serpent/idle'
$biteDir = Join-Path $root 'assets/rhythm/rh_serpent/bite'
New-Item -ItemType Directory -Force -Path $idleDir, $biteDir | Out-Null

foreach ($sheetPath in @($idlePath,$bitePath)) {
    $sheet = [System.Drawing.Bitmap]::new($sheetPath)
    try { if ($sheet.Width % 2 -ne 0 -or $sheet.Height % 2 -ne 0) { throw 'Sprite sheet dimensions must divide evenly into a 2x2 grid.' } }
    finally { $sheet.Dispose() }
}

# One consistent base pose plus subtle cyclic bob; alternate AI face redraws are excluded.
$idleBobs = @(0,-2,0,2)
for ($i=0; $i -lt 4; $i++) {
    [SerpentAssetProcessor]::SaveFrame($idlePath,0,(Join-Path $idleDir ('rh_serpent_idle_{0:D3}.png' -f $i)),$idleBobs[$i],1.0)
}
# Hold bite loop: neutral, open mouth, open mouth, neutral. Both poses share normalized center and scale.
$biteCells = @(0,1,1,0)
for ($i=0; $i -lt 4; $i++) {
    [SerpentAssetProcessor]::SaveFrame($bitePath,$biteCells[$i],(Join-Path $biteDir ('rh_serpent_bite_{0:D3}.png' -f $i)),0,1.0)
}
[SerpentAssetProcessor]::SaveStatic($bodyPath,(Join-Path $root 'assets/rhythm/rh_serpent_body.png'),128,96,$false)
[SerpentAssetProcessor]::SaveStatic($tailPath,(Join-Path $root 'assets/rhythm/rh_serpent_tail.png'),96,96,$true)
Write-Output 'Exported 4 idle frames, 4 bite frames, 128x96 body, and 96x96 tail.'

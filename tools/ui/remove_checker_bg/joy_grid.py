# Dùng chung (exec): cần `a` (H×W×3 float) đã có. Tạo lưới ô, phân loại sáng/tối từng ô, độ phủ nền, trung bình ô.
g = a.mean(axis=2)


def _fit_axis(lines):
    ts, ks = [], []
    for line in lines:
        t_ = np.nonzero(np.diff((line > 72).astype(int)))[0] + 1.0
        ts.append(t_)
        ks.append(np.round(t_ / 11.30))
    t_, k_ = np.concatenate(ts), np.concatenate(ks)
    p_, o_ = np.polyfit(k_, t_, 1)
    keep_ = np.abs(t_ - (o_ + p_ * k_)) < 1.5
    return np.polyfit(k_[keep_], t_[keep_], 1)


px, x0 = _fit_axis([g[y_] for y_ in (2, 4, 6, 837, 839, 841)])
py, y0 = _fit_axis([g[:, x_] for x_ in (2, 4, 6, 1257, 1259, 1261)])
x0 %= px
y0 %= py
NX = int(np.ceil(W / px)) + 3
NY = int(np.ceil(H / py)) + 3
yy, xx = np.mgrid[0:H, 0:W]
ci = np.floor((xx + 0.5 - x0) / px).astype(int) + 1
cj = np.floor((yy + 0.5 - y0) / py).astype(int) + 1
_fx = ((xx + 0.5 - x0) / px) % 1.0
_fy = ((yy + 0.5 - y0) / py) % 1.0
edge_dist = np.minimum(np.minimum(_fx, 1 - _fx) * px, np.minimum(_fy, 1 - _fy) * py)
core = edge_dist > 2.0
_border = np.zeros((H, W), bool)
_border[:22, :] = _border[-22:, :] = True
_border[:, :22] = _border[:, -22:] = True
_bc = _border & core
_lo = g[_bc] < 72
D = np.median(a[_bc][_lo], axis=0)
L = np.median(a[_bc][~_lo], axis=0)


def _c2a(bg_):
    d_ = a - bg_
    up_ = np.where(d_ > 0, d_ / np.maximum(255.0 - bg_, 1.0), 0.0)
    dn_ = np.where(d_ < 0, -d_ / np.maximum(bg_, 1.0), 0.0)
    return np.maximum(up_, dn_).max(axis=2)


def _cell_reduce(v, fn):
    out = np.full((NY, NX) + v.shape[2:], np.nan)
    order = np.lexsort((ci[core], cj[core]))
    keys = cj[core][order] * NX + ci[core][order]
    vals = v[core][order]
    st = np.r_[0, np.nonzero(np.diff(keys))[0] + 1]
    en = np.r_[st[1:], len(keys)]
    for s_, e_ in zip(st, en):
        kk = keys[s_]
        out[kk // NX, kk % NX] = fn(vals[s_:e_])
    return out


_mD = _cell_reduce(_c2a(D[None, None, :]), np.median)
_mL = _cell_reduce(_c2a(L[None, None, :]), np.median)
cell_mean = _cell_reduce(a, lambda v_: np.median(v_, axis=0))
_valid = ~np.isnan(_mD)
light = _mL < _mD
for _it in range(8):
    _ch = np.where(light, _mL, _mD)
    _pd = np.pad(np.where(_valid, _ch, np.nan), 1, constant_values=np.nan)
    _nb = np.nanmedian(np.stack([_pd[:-2, 1:-1], _pd[2:, 1:-1], _pd[1:-1, :-2], _pd[1:-1, 2:],
                                 _pd[:-2, :-2], _pd[:-2, 2:], _pd[2:, :-2], _pd[2:, 2:]]), axis=0)
    _new = np.abs(_mL - _nb) < np.abs(_mD - _nb)
    _new = np.where((np.abs(_mL - _mD) < 0.04) | ~_valid, light, _new)
    if (_new == light).all():
        break
    light = _new
cover = np.zeros((H, W))
_SS = 8
for _sy in range(_SS):
    for _sx in range(_SS):
        _i = np.floor((xx + (_sx + 0.5) / _SS - x0) / px).astype(int) + 1
        _j = np.floor((yy + (_sy + 0.5) / _SS - y0) / py).astype(int) + 1
        cover += light[np.clip(_j, 0, NY - 1), np.clip(_i, 0, NX - 1)]
cover /= _SS * _SS

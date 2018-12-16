// Created by Danil (2018)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// self https://www.shadertoy.com/view/4lKBWh

// using http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
// using https://www.shadertoy.com/view/llyXRW
// using https://www.shadertoy.com/view/ldKyW1

// this is just "demo"
// this is not "universal UI/game engine" this is fast code only for that game/demo
// number cards in hand, its animation and many other thinks are hard coded(no way to change them(without very hard editing))(adding new cards/mechanics also complicated), faster for you will be rewrite the logic by you own

// have fun xD

#define SS(x, y, z) smoothstep(x, y, z)
#define MD(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define PI (4.0 * atan(1.0))
#define TAU (2.*PI)
#define E exp(1.)
#define res (iResolution.xy / iResolution.y)

struct allData_struc {
    float cards_player; //num of cards in player hand
    float card_select_anim; //time of start card select animation
    float card_add_anim; //time of start card add animation
    vec2 mouse_pos;
    float this_selected_card; //hand card selection
    float last_selected_card; //hand card selection
    float card_put_anim; //card put to board from hand
    float card_hID_put_anim; //used only for animation removing card from hand
    float card_bID_put_anim; //last putted card on board
    float flag1;
    float flag0;
    vec2 player_hpmp;
    vec2 en_hpmp;
    float flag3;
    float egt; //end game timer
    float card_draw; //draw X cards
    bool player_turn;
    float ett; //end turn timer
    bool player_etf; //used for "cards on board hit other side"
    bool en_etf; //same
};

allData_struc allData;

const vec3 blue = vec3(0x90, 0xbb, 0xe4) / float(0xff);
const vec3 green = vec3(0x7f, 0xbe, 0x20) / float(0xff);
const vec3 purple = vec3(0x9e, 0x75, 0xaf) / float(0xff);
const vec3 white = vec3(0xdc, 0xe0, 0xd1) / float(0xff);
const vec3 red = vec3(0xa6, 0x36, 0x2c) / float(0xff);
const vec3 redw = vec3(0xfd, 0x8c, 0x77) / float(0xff);
const vec3 sand = vec3(0xe9, 0xdf, 0xc3) / float(0xff);
const vec3 gc = vec3(0x38, 0x38, 0x38) / float(0xff);
const vec3 wc = vec3(0xfc, 0xfc, 0xfc) / float(0xff);
const vec3 gc2 = vec3(0x47, 0x47, 0x47) / float(0xff);

float zv;
vec2 res_g;

// start time from extime value sec, for timers
#define extime 15.
float g_time;

#define C(c) U.x-=.5; T+= U.x<.0||U.x>1.||U.y<0.||U.y>1. ?vec4(0): textureGrad( iChannel3, U/16. + fract( vec2(c, 15-c/16) / 16.), dFdx(U/16.),dFdy(U/16.) )
#define initMsg vec4 T = vec4(0)
#define endMsg  return length(T.yz)==0. ? 0. : T.x

float sdBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + min(max(d.x, d.y), 0.0);
}

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdLine(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdVesica(vec2 p, float r, float d) {
    p = abs(p);
    float b = sqrt(r * r - d * d);
    return ((p.y - b) * d > p.x * b)
            ? length(p - vec2(0.0, b))
            : length(p - vec2(-d, 0.0)) - r;
}

float ndot(vec2 a, vec2 b) {
    return a.x * b.x - a.y * b.y;
}

float sdRhombus(in vec2 p, in vec2 b) {
    vec2 q = abs(p);
    float h = clamp((-2.0 * ndot(q, b) + ndot(b, b)) / dot(b, b), -1.0, 1.0);
    float d = length(q - 0.5 * b * vec2(1.0 - h, 1.0 + h));
    return d * sign(q.x * b.y + q.y * b.x - b.x * b.y);
}

float sdBezier(in vec2 pos, in vec2 A, in vec2 B, in vec2 C) {
    vec2 a = B - A;
    vec2 b = A - 2.0 * B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0 / dot(b, b);
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);
    float resa = 0.0;
    float p = ky - kx*kx;
    float p3 = p * p*p;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p3;
    if (h >= 0.0) {
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x) * pow(abs(x), vec2(1.0 / 3.0));
        float t = uv.x + uv.y - kx;
        t = clamp(t, 0.0, 1.0);
        vec2 qos = d + (c + b * t) * t;
        resa = dot(qos, qos);
    } else {
        float z = sqrt(-p);
        float v = acos(q / (p * z * 2.0)) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp(t, 0.0, 1.0);
        vec2 qos = d + (c + b * t.x) * t.x;
        resa = dot(qos, qos);
        qos = d + (c + b * t.y) * t.y;
        resa = min(resa, dot(qos, qos));
        qos = d + (c + b * t.z) * t.z;
        resa = min(resa, dot(qos, qos));
    }
    return sqrt(resa);
}

float sdTriangleIsosceles(in vec2 q, in vec2 p) {
    p.y -= 0.5;
    p.x = abs(p.x);
    vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    float s = -sign(q.y);
    vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
            vec2(dot(b, b), s * (p.y - q.y)));
    return -sqrt(d.x) * sign(d.y);
}

float board(vec2 p) {
    float d = 0.;
    d = SS(0., zv, sdBox(p, vec2(0.6, 0.3)));
    return d;
}

float card_shadow(vec2 p) {
    float d = 0.;
    d = SS(-0.01, 0.02 + zv, sdBox(p, vec2(0.08, 0.12)));
    return d;
}

float card(vec2 p) {
    float d = 0.;
    d = SS(0., 0.0 + zv, sdBox(p, vec2(0.08, 0.12)));
    return d;
}

float hp_s(vec2 p) {
    float d = 0.;
    d = sdBox(p, vec2(0.06, 0.01));
    d = SS(0., 0.0 + zv, d);
    return d;
}

float hp_s2(vec2 p) {
    float d = 0.;
    d = sdBox(p, vec2(0.045, 0.015));
    d = SS(0., 0.0 + zv, d - 0.03);
    return d;
}

float hp_s3(vec2 p) {
    float d = 0.;
    d = sdBox(p, vec2(0.015, 0.001));
    d = SS(-0.001, 0.008, d);
    return d;
}

float get_animstate(float timeval) {
    return SS(0., 1., timeval);
}

const vec3 cw2 = vec3(0xf8, 0xf9, 0xfb) / float(0xff);
const vec3 cb2 = vec3(0x1c, 0x25, 0x36) / float(0xff);
const vec3 cr2 = vec3(0xe3, 0x6b, 0x7e) / float(0xff);
const vec3 cr3 = vec3(0xec, 0xd0, 0x6a) / float(0xff);

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.1)));
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(in vec2 p) {
    const float K1 = (sqrt(3.) - 1.) / 2.;
    const float K2 = (3. - sqrt(3.)) / 6.;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
    return dot(n, vec3(50.0));
}

float fbm(vec2 uv) {
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
    float f = 0.5000 * noise(uv);
    uv = m*uv;
    f += 0.2500 * noise(uv);
    uv = m*uv;
    f += 0.1250 * noise(uv);
    uv = m*uv;
    f += 0.0625 * noise(uv);
    uv = m*uv;
    f = 0.5 + 0.5 * f;
    return f;
}

float card_fbg(vec2 p) {
    float tx = g_time / 2.;
    float nx = abs(noise(p + vec2(tx * 0.5)));
    nx += 0.5 * abs(noise((p + vec2(-tx * 0.25, tx * 0.25)) * 2.0));
    nx += 0.25 * abs(noise((p + vec2(tx * 0.15, -tx * 0.15)) * 4.0));
    nx += 0.125 * abs(noise((p + vec2(-tx * 0.05, -tx * 0.05)) * 8.0));
    return nx;
}

vec3 card_nbg(vec2 p, float tv) {
    float _s = sign(p.y) * (200.0 + (tv * 0.051));
    float l = p.y;
    p.y = mod(abs(p.y), 2.50);
    p.x += _s + pow(p.y, -1.002);
    vec3 xx = vec3(fbm(p - vec2(0.0, tv * 0.0485)));
    float s = 3.75;
    float m = pow(xx.x, p.y * s) + .05;
    if (l < 0.0) {
        m *= 0.3;
    }
    vec3 color = mix((m / blue), (m / sand), clamp(sin(tv / 20.) - cos(tv / 20.), 0., 1.));
    return clamp(color, vec3(0.), vec3(1.));
}

const vec3 cef1a = vec3(0x69, 0x64, 0x7e) / float(0xff);
const vec3 cef1b = vec3(0xd8, 0x79, 0x8b) / float(0xff);
const vec3 cef2b = vec3(0x1b, 0x5f, 0x41) / float(0xff);
const vec3 cef3a = vec3(0x82, 0x9d, 0xa9) / float(0xff);
const vec3 cef4a = vec3(0xe6, 0x73, 0x00) / float(0xff);
const vec3 cef6a = vec3(0xb3, 0x24, 0x00) / float(0xff);
const vec3 cef7a = vec3(0x33, 0x33, 0xcc) / float(0xff);
const vec3 cef7b = vec3(0x66, 0x99, 0xff) / float(0xff);
const vec3 cef8a = vec3(0x99, 0x00, 0xcc) / float(0xff);
const vec3 cef9a = vec3(0x00, 0x33, 0x00) / float(0xff);

float text_hp(vec2 U) {
    initMsg;C(72);C(80);C(58);endMsg;
}

float text_a(vec2 U) {
    initMsg;C(65);C(84);C(58);endMsg;
}

float text_pmhp(vec2 U, int v) {
    initMsg;C((v * 43 + 45 * (1 - v)));C(72);C(80);endMsg;
}

float text_pat(vec2 U) {
    initMsg;C(43);C(65);C(84);endMsg;
}

float text_ko(vec2 U) {
    initMsg;C(75);C(79);endMsg;
}

float text_des(vec2 U) {
    initMsg;C(68);C(101);C(115);C(116);C(114);C(111);C(121);endMsg;
}

float text_drw(vec2 U) {
    initMsg;C(68);C(114);C(97);C(119);C(32);C(50);endMsg;
}

float text_end(vec2 U) {
    initMsg;C(69);C(110);C(100);endMsg;
}

float text_mi(vec2 U) {
    initMsg;C(45);endMsg;
}

float text_n0(vec2 U) {
    initMsg;C(48);C(48);endMsg;
}

float text_n(vec2 U, float num) {
    if (num < 1.)return text_ko(U);
    initMsg;
    num = floor(num);
    int maxloop = 2;
    bool x = false;
    if (num < 10.) {
        num = num * 10.;
    } else {
        num = floor(num / 10.)+(num * 10. - floor(num / 10.)*100.);
        if ((num < 10.))x = true;
    }
    while (num >= 1.0) {
        if (maxloop-- < 1)break;
        C((48 + int(num) % 10));
        if (x) {
            C(48);
            x = false;
        }
        num /= 10.0;
    }
    endMsg;
}


// to load card pixels only when we need it without reading 20 pixels for every pixel, if use it in load_state

vec4 load_card(int idx) {
    vec2 id = vec2(0, idx) + 0.5;
    return texture(iChannel0, (id) / iResolution.xy);
}

vec4 load_card2(int idx) {
    vec2 id = vec2(1, idx) + 0.5;
    return texture(iChannel0, (id) / iResolution.xy);
}


#define c_bgr -1
#define c_cr 0
#define c_cr2 1
#define c_cr3 2
#define c_at1 3
#define c_at2 4
#define c_he1 5
#define c_he2 6
#define c_pat 7
#define c_mn 8
#define c_de 9

vec3 decodeval(float colz) {
    vec3 retc = vec3(0.);
    retc.x = floor(floor(colz) / 10000.) - 1.;
    retc.y = floor((-(retc.x + 1.)*10000. + floor(colz)) / 100.) - 1.;
    retc.z = floor(-(retc.y + 1.)*100. - (retc.x + 1.)*10000. + floor(colz)) - 1.;
    return retc;
}

float encodeval(vec3 colz) {
    return floor(colz.r)*10000. + 10000. + floor(colz.g)*100. + 100. + floor(colz.b) + 1.;
}

vec3 decodecol(float colz) {
    return decodeval(colz) / 98.;
}

float encodecol(vec3 colz) {
    return encodeval(colz * 98.);
}

bool is_c_cr(int ix) {
    return (ix - 3) < 0; // used only for cards in hand, they have not c_bgr(-1)
    //return ((ix==c_cr)||(ix==c_cr2)||(ix==c_cr3));
}

float is_c_crf(int ix) {
    return clamp(float(ix - 2), 0., 1.);
}

bool is_o_crf(int ix) {
    return (((ix == c_de) || (ix == c_mn) || (ix == c_pat)));
}

float is_h_crf(int ix) {
    return (((ix == c_at1) || (ix == c_at2)) ? 0. : 1.);
}

bool is_H_crf(int ix) {
    return ((ix == c_he1) || (ix == c_he2));
}

float is_v_crf(int ix) {
    return 1. - clamp(float(ix - 7), 0., 1.);
}

float is_d_crf(int ix) {
    return clamp(float(ix - 8), 0., 1.);
}



// long compile time because of this function(mostly because text)

// using if(id==<card_type>)return func_that_generate_unique_texture_col_for_cardID();
// make shader work same fast (card size is small, any card-shader-background can be used)
// but compile time will be extrimly long (using if()func(); I had 5+ min compile time on Windows, and 30 sec on Linux)

// p(0,0) is card center, card size (0.08,0.12)

vec3 card_ubgx(vec2 p, int id, vec4 card_vals) {
    vec3 c1 = decodecol(card_vals.z);
    vec3 crvals = decodeval(card_vals.x);
    vec3 c2 = (c1 + 0.2);
    vec3 c3 = vec3(0.);
    vec3 c4 = p.x > 0. ? cef7a * 1.5 : cr2;
    vec3 col;
    vec3 colt;
    float isc = is_c_crf(id);
    float isv = is_v_crf(id);
    float ish = is_h_crf(id);
    float isd = is_d_crf(id);
    //return isc * vec3(1. * isv, 1. * ish, 1. * isd + ((id == c_pat) ? 1. : 0.)); //this make compile time to few sec (return single color for each card type)
    colt = mix(c1, c2, SS(-0.05, 0.18, p.y));
    col = mix(cw2, colt, SS(0., zv, p.y + 0.05));
    col = mix(col, c3 * isc + c4 * (1. - isc), isv * 0.65 * SS(zv / 2., 0., sdCircle(vec2(abs(p.x)*(1. - isc) + p.x*isc, p.y) - vec2(0.08 * (1. - isc) - 0.08 * isc, 0.12), 0.03)));
    float d = isv * text_n((p + vec2(0.0765, -0.11))*40. + res_g / 2., (1. - isc) * crvals.y + isc * crvals.x);
    col = mix(col, cw2, d);
    if (is_c_cr(id)) {
        d = text_n((p + vec2(-0.059, -0.11))*40. + res_g / 2., crvals.z);
        col = mix(col, cw2, d);
        d = 1. - text_hp((p + vec2(0.07, 0.07))*50. + res_g / 2.);
        d = min(d, 1. - text_a((p + vec2(0.07, 0.095))*50. + res_g / 2.));
        col = col*d;
        d = SS(0.003 - zv / 2., 0.004 + zv / 2., sdLine(p, -vec2(0.04, 0.071), -vec2(0.04 - 0.1 * (min(1., crvals.y / 98.)), 0.071)));
        col = mix(cr2, col, d);
        d = SS(0.003 - zv / 2., 0.004 + zv / 2., sdLine(p, -vec2(0.04, 0.096), -vec2(0.04 - 0.1 * (min(1., crvals.z / 98.)), 0.096)));
        col = mix(cef7a * 1.5, col, d);
    } else {
        if (is_o_crf(id)) {
            if (id == c_pat) {
                d = 1. - text_pat((p + vec2(0.045, 0.08))*15. + res_g / 2.);
                col = mix(vec3(0.5), col, d);
            } else if (id == c_pat) {
                d = 1. - text_pat((p + vec2(0.045, 0.08))*15. + res_g / 2.);
                col = mix(vec3(0.5), col, d);
            } else {
                if (id == c_mn) {
                    d = 1. - text_drw((p + vec2(0.06, 0.08))*25. + res_g / 2.);
                    col = mix(vec3(0.5), col, d);
                } else {
                    d = 1. - text_des((p + vec2(0.06, 0.08))*25. + res_g / 2.);
                    col = mix(vec3(0.5), col, d);
                }
            }
        } else {
            d = 1. - text_pmhp((p + vec2(0.045, 0.08))*15. + res_g / 2., int(ish));
            col = mix(vec3(0.5), col, d);
        }
    }
    float crx2 = (id == c_cr2 ? 1. : 0.);
    float crx3 = (id == c_cr3 ? 1. : 0.);
    if (is_H_crf(id) || (id == c_pat) || (1. - (isv + isd) > 0.)) {
        p.y = -p.y + 0.07;
        ish = 0.;
    }
    float da = (1. - 0.3 * (1. - isv - isd) - 0.2 * (1. - ish)) * SS(0.002 * crx3 + zv / 2., 0.001 * crx3 + 0., max(crx3 * abs(sdCircle(p + vec2(0., -0.035), 0.015)), sdCircle(p + vec2(0., -0.035 + 0.035 * (1. - ish)), 0.015)));
    float db = (isv + isd)*(0.25 * crx2 + 0.25) * SS(zv / 2., 0., sdCircle(p + vec2(0., -0.035 + 0.035 * (1. - ish)), 0.03));
    d = 0.5 * SS(zv / 2., 0., sdBox(p + vec2(0., -0.035 - 0.015), vec2(0.015, 0.05)));
    col = mix(col, cw2, max(min(max((1. - crx2) * da, -da * crx2 + db), 1. * (1. - isd) + SS(0.035, 0.035 - zv, p.y)), d * SS(0.1, 0.0, p.y)*(1. - ish)));
    return col; //-card_nbg((p+vec2(0.,0.15))*8.,g_time/2.+50.*float(id));
}

vec3 load_id_cardcolor(vec2 p, int id, vec4 card_vals) {
    if (id == c_bgr)return card_nbg((p + vec2(0., 0.15))*8., g_time);
    return card_ubgx(p, id, card_vals);
}

vec3 get_cardcolor(vec2 p, int id, bool vb) {
    if (id < 0)return load_id_cardcolor(p, id, vec4(0.));
    vec4 card_vals = vb ? load_card(id) : load_card2(id);
    return load_id_cardcolor(p, int(card_vals.w), card_vals);
}

// same as load_card logic

vec4 load_board(int idx) {
    vec2 id = vec2(3, idx) + 0.5;
    return texture(iChannel0, (id) / iResolution.xy);
}

vec4 load_board2(int idx) {
    vec2 id = vec2(4, idx) + 0.5;
    return texture(iChannel0, (id) / iResolution.xy);
}

vec4 load_eff_buf() {
    vec2 id = vec2(2, 3) + 0.5;
    return texture(iChannel0, (id) / iResolution.xy);
}

vec3 get_boardccolor(vec2 p, int id, bool vb) {
    vec4 card_vals = vb ? load_board(id) : load_board2(id);
    if (id < 0)return load_id_cardcolor(p, id, vec4(0.));
    vec3 tcc = load_id_cardcolor(p, int(card_vals.w), card_vals);
    if (int(card_vals.y) == 1) {
        float v2 = -p.y + 0.12 + zv;
        float dxx = (sdCircle(vec2(abs(p.x), p.y) - vec2(0.08, 0.12), 0.03));
        float dx = 1. - max(SS(zv / 2., 0.00 - zv / 2., dxx), SS(0.00, 0.03, v2));
        if (dx < 1.) {
            float nx = card_fbg((p + card_vals.w)*9.);
            tcc = mix(tcc, -tcc + cef7a / (nx * (1. - dx * 0.99)), dx * (1. - nx)*0.6);
            clamp(tcc, vec3(0.), vec3(1.));
        }
    }
    if (card_vals.y < 0.) {
        float anim_t2 = 1. - get_animstate(clamp((g_time - (-card_vals.y) - 0.5)*2., 0., 1.));
        float nx = card_fbg((p + card_vals.w)*9.);
        tcc = mix((((tcc * (anim_t2) + cef4a / 3. * (1. - anim_t2))) / (nx)), tcc, anim_t2);
    }
    return tcc;
}

vec3 get_boardeff(vec2 p) {
    vec4 card_vals = load_eff_buf();
    return load_id_cardcolor(p, int(card_vals.w), card_vals);
}

vec4 card_put_ani_c(vec2 p) {
    vec3 col = vec3(0.);
    const vec2 card_pos = vec2(0., 0.35);
    const vec2 shift_pos = vec2(0.1, 0.);
    const vec2 sp_pos = vec2(-0.75, 0.35);
    float d = 1.;
    const float angle_pos = 0.045;
    float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
    if ((anim_t2 == 0.) || (allData.flag1 == 1.))return vec4(col, 1.);
    float anim_t = 1. - get_animstate(clamp((g_time - allData.card_put_anim)*4., 0., 1.));
    float ad = allData.cards_player + 1. - 1. * (0.);
    float tv = 0.5 - (ad - (ad / 2.) - allData.card_hID_put_anim);
    vec2 epos = vec2(0., -0.08) * 1.;
    vec2 tuv = p;
    int ts = int(load_eff_buf().w);
    if (ts < 0) {
        if (anim_t > 0.)
            tuv = (p + card_pos - epos * (1. - anim_t) * abs(((ad - 1.) / 2. - allData.card_hID_put_anim) / 6.)) * MD(angle_pos * tv * anim_t) + epos - shift_pos * tv;
        else
            tuv = p + (card_pos - epos * (1. - anim_t) * abs(((ad - 1.) / 2. - allData.card_hID_put_anim) / 6.) + epos - shift_pos * tv) * anim_t2 + (1. - anim_t2)*(vec2(0.18 / 2., 0.1 + 0.005 + zv / 2.) + vec2(0.18 * 2. - 0.18 * allData.card_bID_put_anim, 0.));
        d = card(tuv);
        vec3 cardcol = vec3(0.);
        if (d < 1.)
            cardcol = get_boardccolor(tuv, int(allData.card_bID_put_anim), true);

        float ds = card_shadow(tuv);
        ds = (1., ds + 1. - anim_t2);
        col = col * (ds);
        col = mix(cardcol, col, d);
        d = min(ds, d);
    } else {
        float td = 1.;
        float nx = 1.;
        tuv = (p + card_pos - epos * (1. - anim_t) * abs(((ad - 1.) / 2. - allData.card_hID_put_anim) / 6.)) * MD(angle_pos * tv * anim_t) + epos - shift_pos*tv;
        td = SS(0., 0.01, sdBezier(p, -(card_pos - epos * (1. - 1.) * abs(((ad - 1.) / 2. - allData.card_hID_put_anim) / 6.) + epos - shift_pos * tv),
                vec2(0., 0.12 * 2.)-(card_pos - epos * (anim_t) * abs(((ad - 1.) / 2. - allData.card_hID_put_anim) / 6.) + epos - shift_pos * tv),
                vec2(-0.18 * 3. + 0.18 / 2. + (allData.card_bID_put_anim > 9. ? allData.card_bID_put_anim - 10. : allData.card_bID_put_anim)* 0.18, (allData.card_bID_put_anim > 9. ? 0.135 : -0.12))));
        d = card(tuv);
        if ((d < 1.) || (td < 1.))
            nx = card_fbg(p * 9.);
        vec3 cardcol = vec3(0.);
        if (d < 1.)
            cardcol = get_boardeff(tuv);
        float ds = card_shadow(tuv);
        ds = (1., ds + 1. - anim_t2);
        col = col * (ds);
        col = mix((col + (blue / 2.) / (nx)), col, td);
        col = mix(cardcol, col, d);
        d = min(ds, d);
        float tdx = d;
        d = min(td, d);
        d = max(d, 1. - anim_t2);
        col = mix((((col * (0.5 + anim_t2) + blue / 3. * (1. - anim_t2)) * (1. - tdx)) / (nx)), col, anim_t2);
    }

    return vec4(col, d);
}

vec4 card_put2_ani_c(vec2 p) {
    vec3 col = vec3(0.);
    float d = 1.;
    float td = 1.;
    if ((!allData.player_turn)&&(!allData.en_etf)) {
        if (allData.flag3 == 1.)return vec4(col, d);
        vec4 lbx = load_card2(2);
        if (floor(max(lbx.x, lbx.y)) >= 0.) {
            float anim_t2zb = 1. - get_animstate(clamp((g_time - allData.ett - 8.), 0., 1.));
            const vec2 card_pos = vec2(0., 0.35);
            const vec2 shift_pos = vec2(0.1, 0.);
            const vec2 sp_pos = vec2(-0.75, 0.35);
            float anim_t2 = 1. - get_animstate(clamp((g_time - allData.ett - 4.5 - (2. - 2. * max(lbx.x, lbx.y)))*2., 0., 1.));
            float anim_t = 1. - get_animstate(clamp((g_time - allData.ett - 3.5 - (2. - 2. * max(lbx.x, lbx.y)))*2., 0., 1.));
            vec2 epos = vec2(0., -0.28) * 1.;
            float tvg = floor(floor(max(lbx.x, lbx.y)) == 1. ? lbx.z : lbx.w);
            float tvgz = ((tvg < 0.)&&(tvg != -100.)) ? abs(tvg) - 1. : tvg;
            vec2 epos2 = vec2(0., -0.35 + 0.12 - 0.02 - zv) - sp_pos + (vec2(0.18 / 2., 0.1 + 0.005 + zv / 2.) + vec2(0.18 * 2. - 0.18 * (tvgz > 9. ? tvgz - 10. : tvgz), 0.));
            vec2 tuv = p;
            if ((anim_t > 0.) || (!(tvg >= 0.)))
                tuv = (p + sp_pos + epos * (1. - anim_t));
            else
                tuv = (p + sp_pos + epos * anim_t2 + epos2 * (1. - anim_t2));
            if (!(tvg >= 0.)&&(tvg != -100.)) {
                td = SS(0., 0.01, sdBezier(p, -(sp_pos + epos * (1. - anim_t)),
                        vec2(0., 0.12 * 2.)-(sp_pos + epos * (1. - anim_t)),
                        vec2(-0.18 * 3. + 0.18 / 2. + (tvgz > 9. ? tvgz - 10. : tvgz)* 0.18, (tvgz > 9. ? 0.135 : -0.12))));
                float anim_tl = 1. - get_animstate(clamp((g_time - allData.ett - 4. - (2. - 2. * max(lbx.x, lbx.y)))*3., 0., 1.));
                td = max(td, anim_tl);
            }
            d = card(tuv);
            vec3 cardcol = vec3(0.);
            if (d < 1.)
                cardcol = get_cardcolor(tuv, int(max(lbx.x, lbx.y)), false);

            float ds = card_shadow(tuv);
            ds = (1., ds + 1. - anim_t2);
            col = col * (ds);
            float nx = 1.;
            if ((!(tvg >= 0.))&&((d < 1.) || (td < 1.)))
                nx = card_fbg(p * 9.);
            col = mix((col + (purple / 2.) / (nx)), col, td);
            col = mix(cardcol, col, d);
            d = min(ds, d);
            float tdx = d;
            if (!(tvg >= 0.)) {
                d = min(td, d);
                d = max(d, 1. - anim_t2);
                col = mix((((col * (0.5 + anim_t2) + blue / 3. * (1. - anim_t2)) * (1. - tdx)) / (nx)), col, anim_t2);
            }
        }
    }

    return vec4(col, d);
}

vec4 card_hand(vec2 p) {
    vec3 col = vec3(0.);
    float d = 1.;
    float ds = 1.;
    float da = d;
    float dt = 1.;
    float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
    bool pass = false;
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        return vec4(col, 1.);
    }
    if ((p.y>-0.1) || (p.x<-0.65)) { //save GPU time
        if ((anim_t2 == 0.)&&(allData.player_turn))return vec4(col, 1.);
        else
            pass = true;
    }
    vec2 op = p;
    float anim_t2z = get_animstate(clamp((g_time - allData.ett)*1.5, 0., 1.));
    if (allData.player_turn)p.y += 0.08 * (1. - anim_t2z);
    else p.y += 0.08 * (anim_t2z);
    const vec2 card_pos = vec2(0., 0.35);
    const vec2 shift_pos = vec2(0.1, 0.);
    const vec2 sp_pos = vec2(-0.75, 0.35);
    const float angle_pos = 0.045;
    float anim_t = get_animstate(clamp(1. - (g_time - allData.card_add_anim), 0., 1.));
    vec3 cardcol = vec3(0.);
    vec2 tuv = vec2(0.);
    float ec = -1.;
    ec = allData.card_hID_put_anim;
    float locsc = -1.;
    if (allData.flag1 == 1.)locsc = ec;
    else locsc = allData.last_selected_card;
    vec4 col_t = card_put2_ani_c(op); //draw en cards
    da = min(da, col_t.w); // min to off shadow blink on draw
    col = mix(col_t.rgb, col, col_t.w);
    if (!pass) {
        if (op.y<-0.2) {
            //optimization, calculating tiles to display only this tile+2 previous+2 next without loop all 10 cards(when hand maxsize)
            //save ~15% GPU load on it
            float ist = floor((p.x + (0.4) * (allData.cards_player / 10.)) / 0.1) - 2.;
            float ien = ist + 4.; //change +4. to +3. to display tile borders
            if (allData.cards_player > 1.)
                ist = clamp(ist, 0., allData.cards_player - 1.);
            else ist = 0.;
            for (float i = ist; i < allData.cards_player; i++) {
                if (i > ien)break;
                da = min(d, da);
                //calc card position shift
                float avx = 0.;
                tuv = vec2(0.);
                if ((anim_t2 != 0.)&&(allData.flag1 == 0.)) {
                    if (i >= ec)avx = 1.;
                    if (i < ec)avx = -1.;
                    avx *= anim_t2;
                }
                if (i != locsc) {
                    if ((i + avx) + 2. > allData.cards_player + avx) {
                        float tv = 0.5 - ((allData.cards_player + avx) - ((allData.cards_player + avx) / 2.) - (i + avx));
                        tuv = (p + card_pos) * MD(angle_pos * tv * (1. - anim_t)) - shift_pos * tv * (1. - anim_t) + vec2(sp_pos.x, 0.) * anim_t;
                        d = card(tuv);
                        if (d < 1.)
                            cardcol = get_cardcolor(tuv, int(i), true);
                    } else {
                        float ad = (allData.cards_player + avx) - 1. * (anim_t);
                        float tv = 0.5 - (ad - (ad / 2.) - (i + avx));
                        tuv = (p + card_pos) * MD(angle_pos * tv) - shift_pos*tv;
                        d = card(tuv);
                        if (d < 1.)
                            cardcol = get_cardcolor(tuv, int(i), true);
                    }
                    ds = card_shadow(tuv);
                    col = col * (ds);
                    col = mix(cardcol, col, d);
                    d = min(ds, d);
                    da = (d * da); // not min(), min display sdf borders(not nice)
                }
            }
            ds = card_shadow(op + sp_pos);
            if (ds < 1.) {
                d = card(op + sp_pos);
                col = col * (ds);
                col = mix(get_cardcolor(op + sp_pos, -1, true), col, d);
                d = min(ds, d);
                da = min(d, da); // off shadow on draw
            }
        }
        //draw selected card
        if (locsc >= 0.) {
            float ad = allData.cards_player - 1. * (anim_t);
            float tv = 0.5 - (ad - (ad / 2.) - locsc);
            anim_t = get_animstate(clamp((g_time - allData.card_select_anim)*2., 0., 1.));
            vec2 epos = vec2(0., -0.08) * anim_t;
            tuv = (p + card_pos) * MD(angle_pos * tv) + epos - shift_pos*tv;
            d = card(tuv);
            if (d < 1.)
                cardcol = get_cardcolor(tuv, int(locsc), true);
            ds = card_shadow(tuv);
            col = col * (ds);
            col = mix(cardcol, col, d);
            d = min(ds, d);
            da = (d * da); // same not min()
        }
    }
    col_t = card_put_ani_c(p);
    da = (da * col_t.w); // same not min()
    col = mix(col_t.rgb, col, col_t.w);
    return vec4(col, da);
}

int card_baord_id(vec2 p) {
    return int(floor((p.x + 0.18 * 3.) / 0.18));
}

int hpmp_get_hit(vec2 p) {
    if ((allData.player_etf) || (allData.player_etf))return -1;
    vec2 pt = vec2(p.x - 0.18 / 2. - 0.18 * 3., abs(p.y - 0.01) - 0.125 - zv / 2.);
    bool bv = (p.y - 0.02 < 0.);
    float dz = hp_s2(pt + (bv ? 1. : -1.) * vec2(0., 0.015));
    if (dz < 1.)return bv ? 6 : 16;
    return -1;
}

int card_get_hit(vec2 p) {
    vec2 pt = vec2((mod(p.x, 0.18) - 0.18 / 2.), abs(p.y - 0.02) - 0.125 - zv / 2.);
    float d = card(pt);
    bool bv = (p.y - 0.02 < 0.);
    d = max(d, step(0.18 * 3. + zv / 2., abs(p.x)));
    if (d < 1.)return bv ? card_baord_id(p) : 10 + card_baord_id(p);
    return -1;
}

int turnctrl_get_hit(vec2 p) {
    vec2 pt = vec2(p.x - 0.18 / 2. - 0.18 * 4., (p.y - 0.02));
    float d = SS(0., zv, sdBox(pt, vec2(0.04, 0.008)) - 0.02);
    if (d < 1.)return 1;
    return -1;
}

void card_get_select(vec2 p) {
    float d = 1.;
    const vec2 card_pos = vec2(0., 0.35);
    const vec2 shift_pos = vec2(0.1, 0.);
    const vec2 sp_pos = vec2(-0.75, 0.35);
    const float angle_pos = 0.045;
    allData.this_selected_card = -1.;
    float anim_t = get_animstate(clamp(1. - (g_time - allData.card_add_anim), 0., 1.));
    float anim_t2zb = 1. - get_animstate(clamp((g_time - allData.ett - 6.5), 0., 1.));
    if ((allData.card_draw > 0.) || (anim_t > 0.) || (allData.player_etf) || ((anim_t2zb == 0.)&&(!allData.player_turn)&&(!allData.en_etf)))return;
    float anim_t2z = get_animstate(clamp((g_time - allData.ett)*1.5, 0., 1.));
    if (allData.player_turn)p.y += 0.08 * (1. - anim_t2z);
    else p.y += 0.08 * (anim_t2z);
    for (float i = 0.; i < allData.cards_player + 1.; i++) {
        if (i + 1. > allData.cards_player) {
            break;
        }
        if (i + 2. > allData.cards_player) {
            float tv = 0.5 - (allData.cards_player - (allData.cards_player / 2.) - i);
            d = card((p + card_pos) * MD(angle_pos * tv * (1. - anim_t)) - shift_pos * tv * (1. - anim_t) + vec2(sp_pos.x, 0.) * anim_t);
        } else {
            float ad = allData.cards_player - 1. * (anim_t);
            float tv = 0.5 - (ad - (ad / 2.) - i);
            d = card((p + card_pos) * MD(angle_pos * tv) - shift_pos * tv);
        }
        if ((d < 1.)) {
            allData.this_selected_card = i;
        }
    }
    return;
}

float pattern_bg(vec2 p) {
    float d = 0.;
    p = vec2(mod(p.x + 0.01 * (floor((mod(p.y, 0.04) - 0.02) / 0.02)), 0.02) - 0.01, mod(p.y, 0.02) - 0.01);
    d = SS(-0.001, 0.001, sdCircle(p, 0.0035));
    return d;
}

vec3 gr_bg(vec2 p) {
    vec3 col = mix(gc2, wc, SS(0., 0.2, abs(mod(p.x - 0.2, .4) - 0.2)));
    col = mix(0.2 * col, wc, SS(0., 0.3, abs(mod(p.x + 0.1, .6) - 0.3)));
    return col;
}

float glow(float x, float str, float dist) {
    return dist / pow(x, str);
}

float sinSDF(vec2 st, float A, float offset, float f, float phi) {
    return abs((st.y - offset) + sin(st.x * f + phi) * A);
}

float egbg(vec2 p) {
    float d = 0.;
    d = step(.3, abs(p.y));
    return d;
}

float text_d(vec2 U) {
    initMsg;C(68);C(101);C(102);C(101);C(97);C(116);endMsg;
}

float text_w(vec2 U) {
    initMsg;C(86);C(105);C(99);C(116);C(111);C(114);C(121);endMsg;
}

float text_res(vec2 U) {
    initMsg;C(82);C(101);C(115);C(116);C(97);C(114);C(116);endMsg;
}

vec4 main_c_egscr(in vec2 p, bool gx, float stx) {
    stx += .5;
    vec2 op = p;
    p.y = mod(p.y, 0.6) - 0.3;
    vec2 st = p + 0.5;
    vec3 col = vec3(0.0);
    float time = g_time / 2.0;
    float str = 0.6;
    float dist = 0.02;
    float nSin = 4.0;
    float timeHalfInv = -time * sign(st.x - 0.5);
    float am = cos(st.x * 3.0);
    float offset = 0.5 + sin(st.x * 12.0 + time) * am * 0.05;
    for (float i = 0.0; i < nSin; i++) {
        col += glow(sinSDF(st, am * 0.2, offset, 6.0, timeHalfInv + i * 2.0 * PI / nSin), str, dist);
    }
    vec3 s = cos(6. * st.y * vec3(1, 2, 3) - time * vec3(1, -1, 1)) * 0.5;
    float cut = (st.x + (s.x + s.y + s.z) / 33.0);
    float vf = 3.5;
    col = vec3(abs(smoothstep(-0.01 - (gx ? vf * SS(stx, stx + 2., g_time) : -vf * SS(stx + 2., stx, g_time)), -0.03 - (!gx ? vf * SS(stx, stx + 2., g_time) : -vf * SS(stx + 2., stx, g_time)), 0.5 - cut) - clamp(col, 0.0, 1.0)));
    float d = SS(0.6, 0.59, abs(p.y) + 0.3);
    float dv = SS(0., 0.01, sdVesica(vec2(abs(p.y), p.x) + vec2(0. - 0.3, 0.), 0.3 * SS(stx + 1., stx + 1. + 1., g_time), 0.25 * SS(stx + 1., stx + 1. + 1., g_time)));
    d = (d * dv);
    float dz = 0.;
    if (dv < 1.)
        if (gx)
            dz = (1. - dv) * text_d(op * 15. + vec2(2.25, 0.45)) * SS(stx + 1.5, stx + 1.5 + 1., g_time);
        else
            dz = (1. - dv) * text_w(op * 15. + vec2(2.4, 0.45)) * SS(stx + 1.5, stx + 1.5 + 1., g_time);
    col = mix(vec3(0.), col, d);
    col = mix(col, vec3(.85), dz);
    return vec4(col, 1.0);
}

vec4 main_c_wl(vec2 p) {
    vec3 col = vec3(0.);
    float dx = egbg(p);
    float stx = allData.egt + 01.;
    dx = max(dx, SS(res_g.x * SS(stx + 0.5, stx + 2. + 0.5, g_time), 1.2 * res_g.x * SS(stx, stx + 2., g_time), p.x + res_g.x / 2.));
    col = mix(main_c_egscr(p, allData.player_hpmp.x < 1., stx).rgb, col, dx);
    col += (rand(p) - .5)*.07;
    if ((abs(p.x) < 0.15)&&(p.y<-0.3)) {
        float dxx = 1.25 - text_res(p * 15. + vec2(2.4, 05.8));
        col = mix(vec3(1.), col, dxx);
        dx = min(max(dxx, (1. - SS(stx + 02.5, stx + 2. + 02.5, g_time))), dx);
    }
    return vec4(col, dx);
}

vec4 main_c_bg(vec2 p) {
    vec3 col = vec3(0.);
    float d = pattern_bg(p);
    col = mix(vec3(0.), gc, d);
    float vignetteAmt = 1. - dot(p, p);
    col *= vignetteAmt;
    col += (rand(p) - .5)*.07;
    col *= SS(-0.04, 0.1, abs(abs(p.y) - .3));
    col = mix(col, sqrt(gr_bg(p)*(1. - SS(-0.04, 0.1, abs(abs(p.y) - .3)))), -step(0.3 + 0.002, abs(p.y)) + step(0.3 - 0.002, abs(p.y)));
    bool bv = (p.y - 0.02) < 0.;
    vec2 pt = vec2((mod(p.x, 0.18) - 0.18 / 2.), -(abs(p.y - 0.02) - 0.125 - zv / 2.));
    d = card(pt);
    float dod = step(0.18 * 3., abs(p.x));
    d = max(d, dod);
    vec3 ec = ((bv ? 0.75 * blue : red)*(1. - d));
    col += col * ec;
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        return vec4(col, 1.);
    }
    //both sides of board
    if (dod < 1.)
        if (((!allData.en_etf)&&(bv)) || ((!allData.player_etf)&&(!bv))) {
            if (d < 1.) {
                vec4 lb = bv ? load_board(card_baord_id(p)) : load_board2(card_baord_id(p));
                //display selection of target cells base on card type
                if ((int(lb.w) == c_bgr)) {
                    if ((bv)&&(allData.last_selected_card >= 0.) && (allData.player_turn) &&
                            is_c_cr((int(load_card(int(allData.last_selected_card)).w)))) {
                        float dx = SS(0.01, -0.05, (sdBox(pt, vec2(0.08, 0.12))));
                        float anim_t = 1. - get_animstate(clamp(1. - (g_time - allData.card_select_anim)*2.5, 0., 1.));
                        float nx = card_fbg(p * 9.);
                        col = mix(col + ((ec / 5. * (1. - dx)) / (5. * nx * (dx))) * anim_t, col, d);
                    }
                } else {
                    float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
                    if ((card_baord_id(p) == int(allData.card_bID_put_anim))&&(bv)&&(anim_t2 > 0.)&&(int(load_eff_buf().w) < 0)) {
                    } else {
                        float anim_t2x = 0.;
                        if (lb.y < 0.) {
                            anim_t2x = get_animstate(clamp((g_time - (-lb.y) - 0.5)*2., 0., 1.));
                        }
                        if (!bv)pt.y *= -1.;
                        col = mix(get_boardccolor(pt, card_baord_id(p), bv), col, max(d, anim_t2x));
                        int crr = (int(load_card(int(allData.last_selected_card)).w));
                        if ((allData.last_selected_card >= 0.) && (allData.player_turn) &&
                                is_c_cr((int(lb.w)))&&((c_he1 == crr) || (crr == c_at1) || (crr == c_pat) || (crr == c_de))) {
                            float dx = SS(0.01, -0.05, (sdBox(pt, vec2(0.08, 0.12))));
                            float anim_t = 1. - get_animstate(clamp(1. - (g_time - allData.card_select_anim)*2.5, 0., 1.));
                            float nx = card_fbg(p * 9.);
                            col = mix(col * (1. - 0.35 * anim_t)+ (((c_pat == crr) ? blue : ((c_he1 == crr) ? green : red)) * 2.)*((ec / 5. * (1. - dx)) / (5. * nx * (dx))) * anim_t, col, d);
                        }
                    }
                }
            }
        } else {
            //card hit animation
            vec4 lb = ((allData.en_etf)&&(bv)) ? load_board(card_baord_id(p)) : load_board2(card_baord_id(p));
            float anim_t2za = min(get_animstate(clamp((g_time - allData.ett - 0.4 * float(card_baord_id(p)))*3., 0., 1.)),
                    1. - get_animstate(clamp((g_time - allData.ett - .4 - 0.4 * float(card_baord_id(p)))*8., 0., 1.)));
            anim_t2za *= 1. - allData.flag3;
            if (int(lb.w) != c_bgr) {
                p.y += (((allData.en_etf)&&(bv)) ? 1. : -1.)*0.06 * anim_t2za;
                bv = (p.y - 0.02) < 0.;
                if (((allData.en_etf)&&(bv)) || ((allData.player_etf)&&(!bv))) {
                    vec2 pt = vec2((mod(p.x, 0.18) - 0.18 / 2.), -(abs(p.y - 0.02) - 0.125 - zv / 2.));
                    d = card(pt);
                    d = max(d, step(0.18 * 3., abs(p.x)));
                    if (d < 1.) {
                        float anim_t2zb = 1. - min(get_animstate(clamp((g_time - allData.ett)*6., 0., 1.)),
                                1. - get_animstate(clamp((g_time - allData.ett - 2.5)*4., 0., 1.)));
                        anim_t2zb = max(anim_t2zb, allData.flag3);
                        if (!bv)pt.y *= -1.;
                        col = mix(get_boardccolor(pt, card_baord_id(p), bv), col, d);
                        float ddc = sdTriangleIsosceles(vec2(0.06, 0.03), vec2(pt.x, (bv ? 1. : -1.)*-pt.y) + vec2(0., 0.5 + 0.125)) - 0.02;
                        float ddz = SS(-0.01, 0.02, ddc + 0.025);
                        col = clamp(col, vec3(0.), vec3(1.));
                        if (bv)
                            col = mix(-col + 0.25 * blue / ddz, col, min(1., max(anim_t2zb, ddz) + 0.5));
                        else
                            col = mix(-col + 0.25 * purple / ddz, col * (min(1., max(anim_t2zb, ddz) + 0.5)), min(1., max(anim_t2zb, ddz) + 0.5));
                    }
                }
            } else {
                if (d < 1.)
                    col *= (0.5 + 0.5 * (1. - anim_t2za));
            }
        }


    return vec4(col, 1.);
}

vec4 draw_turnctrl(vec2 p) {
    vec3 col = vec3(0.);
    vec2 pt = vec2(p.x - 0.18 / 2. - 0.18 * 4., (p.y - 0.02));
    float d = SS(0., zv, sdRhombus(pt, vec2(0.06, 0.12)));
    float bxx = sdBox(pt, vec2(0.04, 0.008)) - 0.02;
    float dy = SS(0., zv, bxx);
    float dx = 1.;
    if (dy < 1.)
        dx = 1. - text_end(vec2(pt.x, pt.y)*15. + vec2(01.5, 0.5));
    bool bv = (p.y - 0.02 < 0.);
    float dz = SS(-0.01, 0.02, abs(bxx));
    float anim_t = get_animstate(clamp((g_time - allData.card_select_anim)*2., 0., 1.));
    float anim_t2z = 1. - get_animstate(clamp((g_time - allData.ett)*1.5, 0., 1.));
    float anim_t2za = 1. - get_animstate(clamp((g_time - allData.ett), 0., 1.));
    col = mix(bv ? (allData.player_turn ? green * (1. - anim_t2z) : green * anim_t2z) : (allData.player_turn ? green * anim_t2z : green * (1. - anim_t2z)), vec3(0.), d);
    col = mix(cw2, col, dy);
    col = mix(vec3(0.), col, dx);
    if (allData.player_turn) {
        col = mix(0.5 * (allData.player_hpmp.y > 0. ? cef4a : mix(redw, green, anim_t)) / dz, col, dz);
    } else {
        col = mix(0.5 * (green * anim_t2za) / dz, col, dz);
    }
    d = min(min(min(d + 0.65, dy + 0.4), dz), dx);
    return vec4(clamp(col, vec3(0.), vec3(4.)), min(1., d));
}

vec4 draw_hpmp(vec2 p) {
    vec2 pt = vec2(p.x - 0.18 / 2. - 0.18 * 3., abs(p.y - 0.01) - 0.125 - zv / 2.);
    vec3 col = vec3(0.);
    bool bv = (p.y - 0.02 < 0.);
    float d = 1.;
    float dz = hp_s2(pt + (bv ? 1. : -1.) * vec2(0., 0.015));
    if (dz < 1.) {
        d = hp_s(pt);
        float nx = 1.;
        if (d < 1.)
            nx = card_fbg(p * 18.);
        float ddx = hp_s3(pt + vec2(.022, 0.)+(bv ? 1. : -1.) * vec2(0., -0.02));
        float ddx2 = hp_s3(pt + vec2(-.022, 0.)+(bv ? 1. : -1.) * vec2(0., -0.02));
        float vx = (bv ? allData.player_hpmp.x / 98. : allData.en_hpmp.x / 98.)*0.12 - 0.12 / 2.;
        float nxx = step(vx, pt.x);
        col = mix((bv ? green : redw) / (nx * 3.), col, max(d, nxx));
        float dx = 1. - text_n(vec2(pt.x, bv ? -pt.y : pt.y)*15. + vec2(01.25, 0.), bv ? allData.player_hpmp.x : allData.en_hpmp.x);
        col = mix(white, col, dx);
        d = min(d, dx);
        vec3 tccx = vec3(0.);
        int crr = (int(load_card(int(allData.last_selected_card)).w));
        if (allData.player_turn)
            if (bv) {
                if (((c_mn == crr) || (c_he2 == crr))&&(allData.last_selected_card >= 0.) &&(dz < 1.)) {
                    float anim_tx = 1. - get_animstate(clamp(1. - (g_time - allData.card_select_anim)*2.5, 0., 1.));
                    float td = abs(sdBox(pt + (bv ? 1. : -1.) * vec2(0., 0.015), vec2(0.045, 0.015)) - 0.03);
                    tccx = clamp((c_mn == crr ? blue : green) / (100. * td), vec3(0.), vec3(4.));
                    tccx = tccx*anim_tx;
                }
            } else {
                if ((c_at2 == crr)&&(allData.last_selected_card >= 0.) &&(dz < 1.)) {
                    float anim_tx = 1. - get_animstate(clamp(1. - (g_time - allData.card_select_anim)*2.5, 0., 1.));
                    float td = abs(sdBox(pt + (bv ? 1. : -1.) * vec2(0., 0.015), vec2(0.045, 0.015)) - 0.03);
                    tccx = clamp(redw / (100. * td), vec3(0.), vec3(4.));
                    tccx = tccx*anim_tx;
                }
            }
        col = mix(tccx, col, max(dz + 0.35, 1. - d));
        d = min(d, dz + 0.35);
        float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*3., 0., 1.));
        if (allData.flag1 == 1.)anim_t2 = 0.;
        bool bvx = ((bv) ? allData.player_hpmp.y : allData.en_hpmp.y) > 0.;
        bool bvy = ((bv) ? allData.player_hpmp.y : allData.en_hpmp.y) > 1.;
        if ((!allData.player_turn)&&(!allData.en_etf)) {

            float anim_t2x = 1. - get_animstate(clamp((g_time - allData.ett - 4.5 - (2. - 2. * allData.en_hpmp.y))*2., 0., 1.));
            anim_t2 = anim_t2x;
        }
        anim_t2 = allData.player_turn ? (bv ? anim_t2 : 0.) : (!bv ? anim_t2 : 0.);
        col = mix(col, clamp((bvx ? blue : blue * anim_t2) / ddx, vec3(0.), vec3(4.)), 1. - ddx);
        col = mix(col, clamp((bvy ? blue : (bvx ? blue * anim_t2 : vec3(0.))) / ddx2, vec3(0.), vec3(4.)), 1. - ddx2);
        d = min(d, ddx * ddx2);
    }
    if (allData.en_etf || allData.player_etf) {
        float anim_t2zb = 1. - min(get_animstate(clamp((g_time - allData.ett - 0.1)*3., 0., 1.)),
                1. - get_animstate(clamp((g_time - allData.ett - 2.8)*4., 0., 1.)));
        dz = hp_s2(pt + (bv ? 1. : -1.) * vec2(0., 0.07));
        if (dz < 1.) {
            float dxz = 1.;
            if (floor(allData.egt) > 0.)
                dxz = (allData.player_etf ? !bv : bv) ? 1. : 1. - max(text_mi(vec2(pt.x, bv ? -pt.y : pt.y)*15. + vec2(01.6, -0.76)), text_n(vec2(pt.x, bv ? -pt.y : pt.y)*15. + vec2(01.25, -0.7), allData.egt));
            else
                dxz = (allData.player_etf ? !bv : bv) ? 1. : 1. - max(text_mi(vec2(pt.x, bv ? -pt.y : pt.y)*15. + vec2(01.6, -0.76)), text_n0(vec2(pt.x, bv ? -pt.y : pt.y)*15. + vec2(01.25, -0.7)));
            dxz = max(anim_t2zb, dxz);
            col = mix(redw, col, dxz);
            d = min(d, dxz);
        }
    }
    return vec4(col, min(1., d + 0.35));
}

vec4 main_c(vec2 p) {
    vec3 col = vec3(0.);
    float d = 0.;
    d = board(p);
    col = main_c_bg(p).rgb;
    vec4 col_t = vec4(0.);
    float dz = 0.;
    if (allData.flag3 == 1.) {
        dz = SS(allData.egt + 1., allData.egt + 1.5, g_time);
    }
    col_t = draw_hpmp(p);
    col = mix(col_t.rgb, col, col_t.w);
    col_t = draw_turnctrl(p);
    col = mix(col_t.rgb, col, max(col_t.w, dz));
    col_t = card_hand(p);
    col = mix(col_t.rgb, col, max(col_t.w, dz));
    if (allData.flag3 == 1.) {
        col_t = main_c_wl(p);
        col = mix(col_t.rgb, col, col_t.w);
    }
    return vec4(col, 1.);
}

float zoom_calc(float zv) {
    float ex = 0.0025 * ((1080. * zv) / (iResolution.y));
    return ex;
}

void init_globals() {
    zv = zoom_calc(1.);
    res_g = res;
    g_time = iTime + extime;
}

vec2 click_control() {
    return (iMouse.zw) / iResolution.y - res_g / 2.0;
}

float get_card_col(int id) {
    if (id == c_cr) {
        return encodecol(cb2);
    }
    if (id == c_at1) {
        return encodecol(cef1b);
    }
    if (id == c_he1) {
        return encodecol(green);
    }
    if (id == c_cr2) {
        return encodecol(cef3a);
    }
    if (id == c_cr3) {
        return encodecol(vec3(0.));
    }
    if (id == c_de) {
        return encodecol(cef4a);
    }
    if (id == c_at2) {
        return encodecol(cef6a);
    }
    if (id == c_he2) {
        return encodecol(cef9a);
    }
    if (id == c_mn) {
        return encodecol(cef8a);
    }
    if (id == c_pat) {
        return encodecol(cef7a);
    }
    return encodecol(vec3(0.));
}

vec4 draw_cardx(float id, bool tp) {
    int cid = int(10. * rand(vec2(10. - g_time, 5. + 2. * id + g_time)));
    //balance
    //he1 he2 pat
    float val = encodeval(vec3(floor(1. + 14. * rand(vec2(g_time, id + g_time))), floor(1. + 14. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 14. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (tp)if (cid == c_mn)cid = c_he2; //do not draw "draw" card for AI
    //other types
    if (cid == c_he2)val = encodeval(vec3(floor(1. + 25. * rand(vec2(g_time, id + g_time))), floor(1. + 9. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 9. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (cid == c_at2)val = encodeval(vec3(floor(5. + 10. * rand(vec2(g_time, id + g_time))), floor(1. + 9. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 9. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (cid == c_at1)val = encodeval(vec3(floor(1. + 5. * rand(vec2(g_time, id + g_time))), floor(1. + 9. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 9. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (cid == c_cr)val = encodeval(vec3(floor(1. + 6. * rand(vec2(g_time, id + g_time))), floor(1. + 9. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 9. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (cid == c_cr2)val = encodeval(vec3(floor(1. + 6. * rand(vec2(g_time, id + g_time))), floor(1. + 14. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(5. + 10. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    if (cid == c_cr3)val = encodeval(vec3(floor(1. + 6. * rand(vec2(g_time, id + g_time))), floor(5. + 15. * rand(vec2(g_time, id + 20. * sin(g_time)))), floor(1. + 9. * rand(vec2(0.5 * g_time, id + 20. * cos(g_time))))));
    return vec4(val, 0., get_card_col(cid), float(cid));
}

vec4 update_state(vec4 tc, vec4 tcc2) {
    if (int(tc.w) != c_bgr) {
        if (int(tcc2.w) != c_bgr) {
            vec3 crvals = decodeval(tc.x);
            vec3 crvalsx = decodeval(tcc2.x);
            if (int(tc.y) != 1) {
                crvals.y -= crvalsx.z;
                if (crvals.y <= 0.) {
                    tc.y = -g_time;
                    crvals.y = 0.;
                }
            }
            float rexf = encodeval(crvals);
            tc.x = rexf;
        }
        if (int(tc.y) == 1) tc.y = 0.;
    }
    return tc;
}

//the enemy/AI logic

vec2 en_turn_logic(vec4 card1_val, vec4 card2_val) {
    float r1 = -100.;
    float r2 = -100.;
    vec3 efhpat1 = decodeval(card1_val.x); // order [EF,HP,AT]
    vec3 efhpat2 = decodeval(card2_val.x);
    bool isde = false;
    // cast creature, include check for HP and AT(put this creature against other that HP<=this AT(or ...))
    if (is_c_cr(int(card2_val.w))) {
        float firstnbg = -1.;
        float firstencr = -1.;
        for (int i = 0; i < 6; i++) {
            vec4 tcr2 = load_board2(i);
            vec4 tcr = load_board(i);
            tcr2 = update_state(tcr2, tcr); //because same frame creatures destroyed
            if (tcr2.y < 0.)tcr2.w = float(c_bgr);
            if (int(tcr2.w) == c_bgr) {
                if (firstnbg < 0.)firstnbg = float(i);
                if (int(tcr.w) != c_bgr) {
                    if (firstencr < 0.)firstencr = float(i);
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.x - efhpat2.z <= 0.) {
                        r2 = float(i);
                        break;
                    }
                    if (efhpat2.y - thpat.y > 0.) {
                        r2 = float(i);
                    }
                }
            }
        }
        if (r2 < 0.) {
            if (firstnbg >= 0.)r2 = firstnbg; //put card to first empty background slot
            if (firstencr >= 0.)r2 = firstencr; //put card against enemy creature, even if it this creature die
        }
        if (r2 >= 0.)r2 += 10.;
    } else {
        //cast spells
        //AT
        if (int(card2_val.w) == c_at2) {
            r2 = -6. - 1.;
        }
        //HE
        if (int(card2_val.w) == c_he2) {
            r2 = -16. - 1.;
        }
        //de
        if (int(card2_val.w) == c_de) {
            //slect creature with hightest AT and HP to cast on it
            float latmax = 0.;
            float lhpmax = 0.;
            int lix = -1;
            for (int i = 0; i < 6; i++) {
                vec4 tcr = load_board(i);
                if (int(tcr.w) != c_bgr) {
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.y >= latmax) {
                        if (thpat.x >= lhpmax) {
                            latmax = thpat.y;
                            lhpmax = thpat.x;
                            lix = i;
                        } else if (lix < 0) {
                            latmax = thpat.y;
                            lix = i;
                        }
                    }
                }
            }
            if (lix >= 0)r2 = -float(lix) - 1.;
        }
        //at
        if (int(card2_val.w) == c_at1) {
            //slect creature (HP-this AT)=0 or with hightest AT
            float latmax = 0.;
            int lix = -1;
            int lkk = -1;
            for (int i = 0; i < 6; i++) {
                vec4 tcr = load_board(i);
                if ((int(tcr.w) != c_bgr)&&(int(tcr.y) != 1)) {
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.x - efhpat2.x <= 0.) {
                        lkk = i;
                        isde = true;
                        break;
                    }
                    if (thpat.y >= latmax) {
                        latmax = thpat.y;
                        lix = i;
                    }
                }
            }
            if (lix >= 0)r2 = -float(lix) - 1.;
            if (lkk >= 0)r2 = -float(lkk) - 1.;
        }
        //pat
        if (int(card2_val.w) == c_pat) {
            //slect creature with hightest AT and free lane, or creature wit AT<other side creature_HP
            int lix = -1;
            int lkk = -1;
            float latmax = 0.;
            float latmaxo = 0.;
            for (int i = 0; i < 6; i++) {
                vec4 tcr2 = load_board2(i);
                vec4 tcr = load_board(i);
                tcr2 = update_state(tcr2, tcr);
                if (tcr2.y < 0.)tcr2.w = float(c_bgr);
                if (int(tcr2.w) != c_bgr) {

                    lix = i;
                    if (int(tcr.w) == c_bgr) {
                        vec2 thpat2 = decodeval(tcr2.x).yz;
                        if (thpat2.y >= latmaxo) {
                            lkk = i;
                            latmaxo = thpat2.y;
                        }
                    }
                    if ((int(tcr.w) != c_bgr)&&(int(tcr.y) != 1)) {
                        vec2 thpat = decodeval(tcr.x).yz;
                        vec2 thpat2 = decodeval(tcr2.x).yz;
                        if ((thpat.x - thpat2.y > 0.)&&(thpat.y >= latmax)) {
                            lix = i;
                            latmax = thpat.y;
                        }
                    }
                }
            }
            if (lix >= 0)r2 = -float(lix) - 1. - 10.;
            if (lkk >= 0)r2 = -float(lkk) - 1. - 10.;
        }
        //he
        if (int(card2_val.w) == c_he1) {
            //slect creature with lowest hp
            float lhpmi = 98.;
            int lix = -1;
            for (int i = 0; i < 6; i++) {
                vec4 tcr2 = load_board2(i);
                vec4 tcr = load_board(i);
                tcr2 = update_state(tcr2, tcr);
                if (tcr2.y < 0.)tcr2.w = float(c_bgr);
                if (int(tcr2.w) != c_bgr) {
                    vec2 thpat = decodeval(tcr2.x).yz;
                    if (thpat.x <= lhpmi) {
                        lix = i;
                        lhpmi = thpat.x;
                    }
                }
            }
            if (lix >= 0)r2 = -float(lix) - 1. - 10.;
        }

    }
    //almost same for second card(just include check for previus value)
    if (is_c_cr(int(card1_val.w))) {
        float firstnbg = -1.;
        float firstencr = -1.;
        bool fc = int(card2_val.w) == c_de;
        bool fc2 = int(card2_val.w) == c_at1;
        for (int i = 0; i < 6; i++) {
            vec4 tcr2 = load_board2(i);
            vec4 tcr = load_board(i);
            tcr2 = update_state(tcr2, tcr);
            if (tcr2.y < 0.)tcr2.w = float(c_bgr);
            if (int(tcr2.w) == c_bgr) {
                if (is_c_cr(int(card2_val.w))&&(i == int(r2 - 10.)))continue; //dont cast twice on same board id
                if (firstnbg < 0.)firstnbg = float(i);
                if (fc && (i == int(abs(r2) - 1.)))continue;
                if (fc2 && isde && (i == int(abs(r2) - 1.)))continue;
                if (int(tcr.w) != c_bgr) {
                    if (firstencr < 0.)firstencr = float(i);
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.x - efhpat1.z <= 0.) {
                        r1 = float(i);
                        break;
                    }
                    if (efhpat1.y - thpat.y > 0.) {
                        r1 = float(i);
                    }
                }
            }
        }
        if (r1 < 0.) {
            if (firstnbg >= 0.)r1 = firstnbg;
            if (firstencr >= 0.)r1 = firstencr;
        }
        if (r1 >= 0.)r1 += 10.;
    } else {
        if (int(card1_val.w) == c_at2) {
            r1 = -6. - 1.;
        }
        if (int(card1_val.w) == c_he2) {
            r1 = -16. - 1.;
        }
        if (int(card1_val.w) == c_de) {
            bool fc = int(card2_val.w) == c_de; //dont cast twice
            bool fc2 = int(card2_val.w) == c_at1; //check if it already removed
            float latmax = 0.;
            float lhpmax = 0.;
            int lix = -1;
            for (int i = 0; i < 6; i++) {
                float thpxx = 0.;
                if (fc && (i == int(abs(r2) - 1.)))continue;
                if (fc2 && isde && (i == int(abs(r2) - 1.)))continue;
                if (fc2 && (i == int(abs(r2) - 1.)))thpxx -= efhpat2.x;
                vec4 tcr = load_board(i);
                if (int(tcr.w) != c_bgr) {
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.y >= latmax) {
                        if (thpat.x + thpxx >= lhpmax) {
                            latmax = thpat.y;
                            lhpmax = thpat.x + thpxx;
                            lix = i;
                        } else if (lix < 0) {
                            latmax = thpat.y;
                            lix = i;
                        }
                    }
                }
            }
            if (lix >= 0)r1 = -float(lix) - 1.;
        }
        if (int(card1_val.w) == c_at1) {
            bool fc = int(card2_val.w) == c_de; //check if it already removed
            bool fc2 = int(card2_val.w) == c_at1; //check if it already removed
            float latmax = 0.;
            int lix = -1;
            int lkk = -1;
            for (int i = 0; i < 6; i++) {
                float thpxx = 0.;
                if (fc && (i == int(abs(r2) - 1.)))continue;
                if (fc2 && isde && (i == int(abs(r2) - 1.)))continue;
                if (fc2 && (i == int(abs(r2) - 1.)))thpxx -= efhpat2.x;
                vec4 tcr = load_board(i);
                if ((int(tcr.w) != c_bgr)&&(int(tcr.y) != 1)) {
                    vec2 thpat = decodeval(tcr.x).yz;
                    if (thpat.x - thpxx - efhpat1.x <= 0.) {
                        lkk = i;
                        isde = true;
                        break;
                    }
                    if (thpat.y >= latmax) {
                        latmax = thpat.y;
                        lix = i;
                    }
                }
            }
            if (lix >= 0)r1 = -float(lix) - 1.;
            if (lkk >= 0)r1 = -float(lkk) - 1.;
        }
        if (int(card1_val.w) == c_pat) {
            int lix = -1;
            int lkk = -1;
            float latmax = 0.;
            float latmaxo = 0.;
            bool fc = int(card2_val.w) == c_pat; //dont cast twice
            for (int i = 0; i < 6; i++) {
                if (fc && (i == int(abs(r2) - 1. - 10.)))continue;
                vec4 tcr2 = load_board2(i);
                vec4 tcr = load_board(i);
                tcr2 = update_state(tcr2, tcr);
                if (tcr2.y < 0.)tcr2.w = float(c_bgr);
                if (is_c_cr(int(card2_val.w))&&(i == int(r2 - 10.)))tcr2 = card2_val; //self(this frame caster creature) cast
                if (int(tcr2.w) != c_bgr) {
                    lix = i;
                    if (int(tcr.w) == c_bgr) {
                        vec2 thpat2 = decodeval(tcr2.x).yz;
                        if (thpat2.y >= latmaxo) {
                            lkk = i;
                            latmaxo = thpat2.y;
                        }
                    }
                    if ((int(tcr.w) != c_bgr)&&(int(tcr.y) != 1)) {
                        vec2 thpat = decodeval(tcr.x).yz;
                        vec2 thpat2 = decodeval(tcr2.x).yz;
                        if ((thpat.x - thpat2.y > 0.)&&(thpat.y >= latmax)) {
                            lix = i;
                            latmax = thpat.y;
                        }
                    }
                }
            }
            if (lix >= 0)r1 = -float(lix) - 1. - 10.;
            if (lkk >= 0)r1 = -float(lkk) - 1. - 10.;
        }
        if (int(card1_val.w) == c_he1) {
            float lhpmi = 98.;
            int lix = -1;
            bool fc2 = int(card2_val.w) == c_he1;
            for (int i = 0; i < 6; i++) {
                float thpxx = 0.;
                if (fc2 && (i == int(abs(r2) - 1. - 10.)))thpxx += efhpat2.x;
                vec4 tcr2 = load_board2(i);
                vec4 tcr = load_board(i);
                tcr2 = update_state(tcr2, tcr);
                if (tcr2.y < 0.)tcr2.w = float(c_bgr);
                if (is_c_cr(int(card2_val.w))&&(i == int(r2 - 10.)))tcr2 = card2_val; //self cast
                if (int(tcr2.w) != c_bgr) {
                    vec2 thpat = decodeval(tcr2.x).yz;
                    if (thpat.x + thpxx <= lhpmi) {
                        lix = i;
                        lhpmi = thpat.x + thpxx;
                    }
                }
            }
            if (lix >= 0)r1 = -float(lix) - 1. - 10.;
        }
    }
    return vec2(r1, r2);
}

void card_logic(out vec4 fragColor, in vec2 fragCoord, ivec2 ipx) {
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        float val = encodeval(vec3(float(20 + ipx.y), float(1 + ipx.y), float(10 + ipx.y)));
        fragColor = vec4(val, 0., get_card_col(ipx.y), float(ipx.y)); //this not used
        if (ipx == ivec2(1, 2))fragColor = vec4(-1., -1., 0., 0.);
        return;
    }
    if (ipx.x == 0) {
        if (allData.flag1 == 1.) {
            if (int(allData.card_hID_put_anim) <= ipx.y) {
                fragColor = load_card(ipx.y + 1);
                return;
            }
            if (int(allData.card_hID_put_anim) > ipx.y) {
                fragColor = load_card(ipx.y);
                return;
            }
        }
        float anim_t = get_animstate(clamp(1. - (g_time - allData.card_add_anim), 0., 1.));
        float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
        if ((anim_t == 0.)&&(anim_t2 == 0.)&&(allData.card_draw > 0.)) {
            if (ipx.y == int(allData.cards_player)) {
                fragColor = draw_cardx(float(ipx.y), false);
                return;
            }
        }
        fragColor = load_card(ipx.y);
        return;
    }
    if (ipx.x == 1) {
        if (allData.flag3 == 0.)
            if ((!allData.player_turn)&&(allData.en_etf)) {
                if (ipx.y == 2) {
                    vec4 tcc = load_card2(ipx.y);
                    if (tcc.x < 0.) {
                        vec4 tcc2 = load_card2(0);
                        vec4 tcc3 = load_card2(1);
                        float tch1 = -10.;
                        float tch2 = -10.;
                        float xx = -10.;
                        if ((tcc2.x > 0.)&&(tcc3.x > 0.)) {
                            vec2 tcx = en_turn_logic(tcc2, tcc3);
                            tch1 = tcx.y;
                            tch2 = tcx.x;
                            xx = 1.;
                        }
                        fragColor = vec4(xx, -.1, tch1, tch2);
                    } else fragColor = load_card2(ipx.y);
                    return;
                } else
                    if (ipx.y < 2) {
                    vec4 tcc = load_card2(ipx.y);
                    if (tcc.x < 0.)
                        tcc = draw_cardx(float(ipx.y), true); //draw card for en turn
                    fragColor = tcc;
                } else
                    fragColor = vec4(-10.);
                return;
            } else
                if ((!allData.player_turn)&&(!allData.en_etf)) {
                vec4 tcc = load_card2(ipx.y);
                if (ipx.y == 2) {
                    if (floor(tcc.y) >= 0.)tcc.y = -1.;
                    if (floor(tcc.x) >= 0.) {
                        float anim_t2 = 1. - get_animstate(clamp((g_time - allData.ett - 4.5 - (2. - 2. * tcc.x))*2., 0., 1.));
                        if (anim_t2 == 0.) {
                            tcc.y = floor(tcc.x);
                            tcc.x = floor(tcc.x) - 1.;
                        }
                    }
                }
                fragColor = tcc;
                return;
            } else {
                fragColor = vec4(-10.);
                return;
            };
    }
    fragColor = vec4(0.);
    return;
}

void board_logic(out vec4 fragColor, in vec2 fragCoord, ivec2 ipx) {
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        fragColor = vec4(0., 0., 0., -1.);
        return;
    }

    if (ipx.x == 3) {
        vec4 tc = load_board(ipx.y);
        if (allData.flag3 == 1.) {
            fragColor = tc;
            return;
        }
        float anim_t2za = 1. - get_animstate(clamp((g_time - allData.ett - 2.), 0., 1.));
        //work once beucase player_etf change with same timer
        if ((allData.player_turn)&&(anim_t2za == 0.)&&(allData.player_etf)) {
            vec4 tcc2 = load_board2(ipx.y);
            fragColor = update_state(tc, tcc2);
            return;
        }
        if ((!allData.player_turn)&&(!allData.en_etf)) {
            vec4 tcc = load_card2(2);
            if (floor(tcc.y) >= 0.) {
                vec4 tcc2x = load_card2(int(tcc.y));
                if ((int(tcc.z) < 0)&&(int(tcc.z) != -100)) {
                    if ((int(tcc2x.w) == c_de)&&((floor(tcc.y) == 1. ? (abs(int(tcc.z)) - 1) : (abs(int(tcc.w)) - 1)) == ipx.y)) {
                        tc.y = -g_time;
                        fragColor = tc;
                        return;
                    }
                    if ((int(tcc2x.w) == c_at1)&&((floor(tcc.y) == 1. ? (abs(int(tcc.z)) - 1) : (abs(int(tcc.w)) - 1)) == ipx.y)) {
                        vec3 crvals = decodeval(tc.x);
                        vec3 crvalsx = decodeval(tcc2x.x);
                        if (int(tc.y) == 1) {
                            fragColor = tc;
                            return;
                        }
                        crvals.y -= crvalsx.x;
                        if (crvals.y <= 0.) {
                            tc.y = -g_time;
                            crvals.y = 0.;
                        }
                        float rexf = encodeval(crvals);
                        tc.x = rexf;
                        fragColor = tc;
                        return;
                    }
                }
            }
        }
        if (allData.last_selected_card >= 0.) {
            float anim_t = get_animstate(clamp((g_time - allData.card_select_anim)*2., 0., 1.));
            if (anim_t >= 1.) {
                if (card_get_hit(allData.mouse_pos) == ipx.y) {

                    vec4 tc2 = load_card(int(allData.last_selected_card));
                    if ((int(tc.w) == c_bgr)&&(is_c_cr(int(tc2.w)))) {
                        fragColor = tc2;
                        return;
                    }
                }
            }
        }
        if (tc.y < 0.) {
            float anim_t2 = 1. - get_animstate(clamp((g_time - (-tc.y) - 0.5)*2., 0., 1.));
            if (anim_t2 == 0.)fragColor = vec4(0., 0., 0., -1.);
            else fragColor = tc;
            return;
        }
        if ((allData.flag1 == 1.)&&(ipx.y == int(allData.card_bID_put_anim))) {
            vec4 tcx = load_eff_buf();
            vec4 ctx = load_board(int(allData.card_bID_put_anim));
            if ((int(tcx.w) == c_he1)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc.x);
                vec3 crvalsx = decodeval(tcx.x);
                crvals.y += crvalsx.x;
                if (crvals.y > 98.)crvals.y = 98.;
                float rexf = encodeval(crvals);
                tc.x = rexf;
                fragColor = tc;
                return;
            }
            if ((int(tcx.w) == c_at1)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc.x);
                vec3 crvalsx = decodeval(tcx.x);
                if (int(tc.y) == 1) {
                    fragColor = tc;
                    return;
                }
                crvals.y -= crvalsx.x;
                if (crvals.y <= 0.) {
                    tc.y = -g_time;
                    crvals.y = 0.;
                }
                float rexf = encodeval(crvals);
                tc.x = rexf;
                fragColor = tc;
                return;
            }
            if ((int(tcx.w) == c_de)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                tc.y = -g_time;
                fragColor = tc;
                return;
            }
            if ((int(tcx.w) == c_pat)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc.x);
                vec3 crvalsx = decodeval(tcx.x);
                crvals.z += crvalsx.x;
                if (crvals.z > 98.)crvals.z = 98.;
                float rexf = encodeval(crvals);
                tc.x = rexf;
                tc.y = 1.;
                fragColor = tc;
                return;
            }

        }
        fragColor = tc;
        return;
    }
    if (ipx.x == 4) {
        vec4 tc2 = load_board2(ipx.y);
        if (allData.flag3 == 1.) {
            fragColor = tc2;
            return;
        }
        float anim_t2za = 1. - get_animstate(clamp((g_time - allData.ett - 2.), 0., 1.));
        if ((!allData.player_turn)&&(anim_t2za == 0.)&&(allData.en_etf)) {
            vec4 tcc2 = load_board(ipx.y);
            fragColor = update_state(tc2, tcc2);
            ;
            return;
        }
        if ((!allData.player_turn)&&(!allData.en_etf)) {
            vec4 tcc = load_card2(2);
            if (floor(tcc.y) >= 0.) {
                vec4 tcc2x = load_card2(int(tcc.y));
                if ((is_c_cr(int(tcc2x.w)))&&((floor(tcc.y) == 1. ? (int(tcc.z) - 10) : (int(tcc.w) - 10)) == ipx.y)) {
                    tc2 = tcc2x;
                }
                if (((int(tcc2x.w) == c_pat)&&(floor(tcc.y) == 1. ? (abs(int(tcc.z)) - 10 - 1) : (abs(int(tcc.w)) - 10 - 1)) == ipx.y)) {
                    vec3 crvals = decodeval(tc2.x);
                    vec3 crvalsx = decodeval(tcc2x.x);
                    crvals.z += crvalsx.x;
                    if (crvals.z > 98.)crvals.z = 98.;
                    float rexf = encodeval(crvals);
                    tc2.x = rexf;
                    tc2.y = 1.;
                    fragColor = tc2;
                }
                if (((int(tcc2x.w) == c_he1)&&(floor(tcc.y) == 1. ? (abs(int(tcc.z)) - 10 - 1) : (abs(int(tcc.w)) - 10 - 1)) == ipx.y)) {
                    vec3 crvals = decodeval(tc2.x);
                    vec3 crvalsx = decodeval(tcc2x.x);
                    crvals.y += crvalsx.x;
                    if (crvals.y > 98.)crvals.y = 98.;
                    float rexf = encodeval(crvals);
                    tc2.x = rexf;
                    fragColor = tc2;
                }
            }
        }

        if (tc2.y < 0.) {
            float anim_t2 = 1. - get_animstate(clamp((g_time - (-tc2.y) - 0.5)*2., 0., 1.));
            if (anim_t2 == 0.)fragColor = vec4(0., 0., 0., -1.);
            else fragColor = tc2;
            return;
        }
        if ((allData.flag1 == 1.)&&(ipx.y == int(allData.card_bID_put_anim) - 10)) {
            vec4 tcx = load_eff_buf();
            vec4 ctx = load_board2(int(allData.card_bID_put_anim) - 10);
            if ((int(tcx.w) == c_he1)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc2.x);
                vec3 crvalsx = decodeval(tcx.x);
                crvals.y += crvalsx.x;
                if (crvals.y > 98.)crvals.y = 98.;
                float rexf = encodeval(crvals);
                tc2.x = rexf;
                fragColor = tc2;
                return;
            }
            if ((int(tcx.w) == c_at1)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc2.x);
                vec3 crvalsx = decodeval(tcx.x);
                if (int(tc2.y) == 1) {
                    fragColor = tc2;
                    return;
                }
                crvals.y -= crvalsx.x;
                if (crvals.y <= 0.) {
                    tc2.y = -g_time;
                    crvals.y = 0.;
                }
                float rexf = encodeval(crvals);
                tc2.x = rexf;
                fragColor = tc2;
                return;
            }
            if ((int(tcx.w) == c_de)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                tc2.y = -g_time;
                fragColor = tc2;
                return;
            }
            if ((int(tcx.w) == c_pat)&&(is_c_cr(int(ctx.w)))&&(int(ctx.w) != c_bgr)) {
                vec3 crvals = decodeval(tc2.x);
                vec3 crvalsx = decodeval(tcx.x);
                crvals.z += crvalsx.x;
                if (crvals.z > 98.)crvals.z = 98.;
                float rexf = encodeval(crvals);
                tc2.x = rexf;
                tc2.y = 1.;
                fragColor = tc2;
                return;
            }
        }
        fragColor = tc2;
        return;
    }
    fragColor = vec4(0., 0., 0., -1.);
    return;

}

void effect_buf_logic(out vec4 fragColor, in vec2 fragCoord, ivec2 ipx) {
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        fragColor = vec4(0., 0., 0., -1.);
        return;
    }
    vec4 retx = vec4(0., 0., 0., -1.);
    float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
    if (anim_t2 > 0.) {
        retx = load_eff_buf();
    }

    if (allData.last_selected_card >= 0.) {
        float anim_t = get_animstate(clamp((g_time - allData.card_select_anim)*2., 0., 1.));
        if (anim_t >= 1.) {
            if (card_get_hit(allData.mouse_pos) >= 0) {
                vec4 tc = load_board((card_get_hit(allData.mouse_pos) > 9 ? card_get_hit(allData.mouse_pos) - 10 : card_get_hit(allData.mouse_pos)));
                vec4 tc2 = load_card(int(allData.last_selected_card));
                if ((is_c_cr(int(tc.w)))&&(!is_c_cr(int(tc2.w))))
                    fragColor = tc2;
                else
                    fragColor = retx;
                return;
            }
            if (hpmp_get_hit(allData.mouse_pos) > 0) {
                vec4 tc2 = load_card(int(allData.last_selected_card));
                fragColor = tc2;
                return;
            }
        }
    }
    fragColor = retx;
    return;
}

float get_smhp() {
    float retv = 0.;
    for (int j = 0; j < 10; j++) {
        vec4 card_vals = load_board(j);
        vec4 card_vals2 = load_board2(j);
        if ((int(card_vals.w) != c_bgr)&&(int(card_vals2.w) == c_bgr)) {
            vec3 crvals = decodeval(card_vals.x);
            retv += crvals.z;
        }
    }
    return retv;
}

float get_smhp2() {
    float retv = 0.;
    for (int j = 0; j < 10; j++) {
        vec4 card_vals = load_board2(j);
        vec4 card_vals2 = load_board(j);
        if ((int(card_vals.w) != c_bgr)&&(int(card_vals2.w) == c_bgr)) {
            vec3 crvals = decodeval(card_vals.x);
            retv += crvals.z;
        }
    }
    return retv;
}

void hpmp_logic(out vec4 fragColor, in vec2 fragCoord, ivec2 ipx) {
    if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
        fragColor = vec4(encodeval(vec3(0., 80., 2.)), encodeval(vec3(0., 80., 0.)), -1., 0.);
        return;
    }
    float gegt = allData.egt;
    float player_etfl = allData.player_etf ? 1. : 0.;
    float en_etfl = allData.en_etf ? 1. : 0.;
    if (allData.player_turn)allData.en_hpmp.y = 0.;
    else allData.player_hpmp.y = 0.;
    float tpt = allData.ett;
    if (allData.player_turn)tpt = -tpt;
    if ((turnctrl_get_hit(allData.mouse_pos) > 0)&&(!allData.player_etf)) {
        if (allData.player_turn) {
            tpt = g_time;
            allData.en_hpmp.y = 2.;
            en_etfl = 1.;
        }
    }
    if ((!allData.player_turn)&&(!allData.en_etf)) {
        vec4 tc2 = load_card2(2);
        allData.en_hpmp.y = tc2.x;
        if (allData.en_hpmp.y < 0.)allData.en_hpmp.y = 0.;
    }
    if ((!allData.player_turn)&&(allData.flag3 == 0.)&&(allData.en_etf)) {
        gegt = get_smhp();
        if (gegt > 98.)gegt = 98.;
    }
    if ((allData.player_turn)&&(allData.flag3 == 0.)&&(allData.player_etf)) {
        gegt = get_smhp2();
        if (gegt > 98.)gegt = 98.;
    }
    // enemy turn logic
    if ((!allData.player_turn)&&(!allData.en_etf)) {
        float anim_t2zb = 1. - get_animstate(clamp((g_time - allData.ett - 7.), 0., 1.)); // (7-2)=5 sec for enemy turn
        if (anim_t2zb == 0.) {
            tpt = -g_time;
            allData.player_hpmp.y = 2.;
            player_etfl = 1.;
        }
        vec4 tcc = load_card2(2);
        if (floor(tcc.y) >= 0.) {
            vec4 tcc2x = load_card2(int(tcc.y));
            if (int(tcc2x.w) == c_at2) {
                vec3 crvalsx = decodeval(tcc2x.x);
                float thpv = allData.player_hpmp.x - crvalsx.x;
                float egtx = 0.;
                if (thpv < 1.) {
                    thpv = 0.;
                    egtx = g_time;
                };
                fragColor = vec4(encodeval(vec3(player_etfl, thpv, allData.player_hpmp.y)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, egtx);
                return;
            }
            if (int(tcc2x.w) == c_he2) {
                vec3 crvalsx = decodeval(tcc2x.x);
                float thpv = allData.en_hpmp.x + crvalsx.x;
                if (thpv > 98.)thpv = 98.;
                fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, thpv, allData.en_hpmp.y)), tpt, gegt);
                return;
            }

        }
        fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
        return;
    }
    // en cards->player cards
    if ((allData.player_turn)&&(allData.player_etf)) {
        float anim_t2zc = 1. - get_animstate(clamp((g_time - allData.ett - 2.), 0., 1.)); //3 sec for board hit animation
        if (anim_t2zc == 0.) {
            player_etfl = 0.;
            float thpv = allData.player_hpmp.x;
            thpv += -get_smhp2();
            float egtx = 0.;
            if (thpv < 1.) {
                thpv = 0.;
                egtx = g_time;
            };
            fragColor = vec4(encodeval(vec3(player_etfl, thpv, allData.player_hpmp.y)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, egtx);
            return;
        }
        fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
        return;
    }
    // player cards->en_cards
    if ((!allData.player_turn)&&(allData.en_etf)) {
        float anim_t2za = 1. - get_animstate(clamp((g_time - allData.ett - 2.), 0., 1.)); //3 sec for board hit animation
        if (anim_t2za == 0.) {
            en_etfl = 0.;
            float thpv = allData.en_hpmp.x;
            thpv += -get_smhp();
            float egtx = 0.;
            if (thpv < 1.) {
                thpv = 0.;
                egtx = g_time;
            };
            fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, thpv, allData.en_hpmp.y)), tpt, egtx);
            return;
        }
        fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
        return;
    }
    if ((allData.flag1 == 1.)) {
        vec4 tcx = load_eff_buf();
        if (allData.card_bID_put_anim == 6.)
            if ((int(tcx.w) == c_he2)) {
                vec3 crvalsx = decodeval(tcx.x);
                float thpv = allData.player_hpmp.x + crvalsx.x;
                if (thpv > 98.)thpv = 98.;
                float tmpv = allData.player_hpmp.y - 1.;
                if (tmpv < 0.)tmpv = 0.;
                fragColor = vec4(encodeval(vec3(player_etfl, thpv, tmpv)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
                return;
            }
        if (allData.card_bID_put_anim == 16.)
            if ((int(tcx.w) == c_at2)) {
                vec3 crvalsx = decodeval(tcx.x);
                float thpv = allData.en_hpmp.x - crvalsx.x;
                float egtx = 0.;
                if (thpv < 1.) {
                    thpv = 0.;
                    egtx = g_time;
                };
                float tmpv = allData.player_hpmp.y - 1.;
                if (tmpv < 0.)tmpv = 0.;
                fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp.x, tmpv)), encodeval(vec3(en_etfl, thpv, allData.en_hpmp.y)), tpt, egtx);
                return;
            }
    }
    if (allData.flag1 == 1.) {
        float tmpv = allData.player_hpmp.y - 1.;
        if (tmpv < 0.)tmpv = 0.;
        fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp.x, tmpv)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
        return;
    }
    fragColor = vec4(encodeval(vec3(player_etfl, allData.player_hpmp)), encodeval(vec3(en_etfl, allData.en_hpmp)), tpt, gegt);
    return;
}

// load last state

void load_state(in vec2 fragCoord, bool ctrl) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 px = texture(iChannel0, vec2(2.5, 0.5) / iResolution.xy);
    float cards_player = floor(px.x);
    float flag0 = floor(px.y);
    float cards_player_atime = (px.z);
    float cards_player_select = floor(px.w);
    px = texture(iChannel0, vec2(2.5, 2.5) / iResolution.xy);
    float card_put_anim = (px.x);
    float card_hID_put_anim = floor(px.y);
    float card_bID_put_anim = floor(px.z);
    float flag1 = floor(px.w);
    vec2 click_pos = vec2(0.);
    float card_select_anim;
    px = texture(iChannel0, vec2(2.5, 4.5) / iResolution.xy);
    vec3 tvg = decodeval(px.x);
    vec2 player_hpmp = tvg.yz;
    bool player_etf = tvg.x == 1.;
    tvg = decodeval(px.y);
    vec2 en_hpmp = tvg.yz;
    bool en_etf = tvg.x == 1.;
    float ett = px.z;
    bool player_turn = ett < 0.;
    ett = abs(ett);
    float flag3 = 0.;
    float egt = px.w;
    if ((flag0 != 1.) || (g_time < extime + 0.1)) {
        egt = 0.;
    } else {
        if (player_hpmp.x < 1.) {
            flag3 = 1.;
            egt = px.w;
        }
        if (en_hpmp.x < 1.) {
            flag3 = 1.;
            egt = px.w;
        }
    }
    if ((iMouse.z > 0.)&&(ctrl)) {
        float anim_t2 = 1. - get_animstate(clamp((g_time - card_put_anim - 0.5)*2., 0., 1.));
        float anim_t = get_animstate(clamp(1. - (g_time - cards_player_atime), 0., 1.));
        if ((flag3 == 0.)&&(anim_t == 0.)&&(anim_t2 == 0.)) { //do not update mouse if anim played
            click_pos = click_control();
            if ((player_hpmp.y > 0.)&&((card_get_hit(click_pos) >= 0) || (hpmp_get_hit(click_pos) > 0))) {
                px = texture(iChannel0, vec2(2.5, 1.5) / iResolution.xy);
                card_select_anim = px.z;
            } else card_select_anim = g_time;
        } else {
            card_select_anim = g_time;
        }
    } else {
        px = texture(iChannel0, vec2(2.5, 1.5) / iResolution.xy);
        card_select_anim = px.z;
        click_pos = px.xy;
    }
    px = texture(iChannel0, vec2(2.5, 1.5) / iResolution.xy);
    float card_draw = floor(px.w);
    if(flag3==1.)card_draw=0.;
    allData = allData_struc(cards_player, card_select_anim, cards_player_atime, click_pos, -1., cards_player_select, card_put_anim, card_hID_put_anim, card_bID_put_anim, flag1, flag0,
            player_hpmp, en_hpmp, flag3, egt, card_draw, player_turn, ett, player_etf, en_etf);
}

// save state used pixels, to [0-5,0-10]
// pixel [0,0-9] <x> player cards player
// <y> 0 to 9 is card (10 cards)

// pixel [1,0-2] other side hand  <y> 0-1 two cards for this turn on opponent
// <y>=2 (x num of cards to draw left, y last state of x, z where to put first, w where to put second)

// card pixel values vec4[(EF/HP/AT) as float, ST, COL, ID] EF its effect value if card is not creature
// ID its card ID
// COL card background color
// ST card state(effect on card, like freezed/has shield/any other mechanic) (ST<0. for card destroy animation, ST>0 1/2/3/etc index of state)

// pixel [2,0]
// vec4[cards in player hand, Flag0, time player card added anim, mouse selected card]
// Flag0 signal(0/1) if this launched

// pixel [2,1]
// vec4[last iMouse.zw, time when card selected, draw control]

// pixel [2,2]
// vec4[time card to board anim, ID on hand, ID in board, Flag1]
// Flag1 signal(0/1) if need to remove card from hand on this frame(once) for cards in hand array

// pixel [2,3]
// pixel values vec4[EF/HP/AT, ST, COL, ID]
// used to save "last played effect card"

// pixel [2,4]
// vec4[encodeval(ETF, Plyer HP, player Manna), encodeval(ETF, Enemy HP, Enemy Manna),player turn,egt]
// player turn +-g_time,time when End clicked +- player/opponent turn
// egt=end game time, also used to save -hp value(number) on "cardhit animation" when game not ended
// ETF=flag for both hp, (1/0) if "end turn -hp" animation is done (to make it work once)

// pixel <x> 3 to 4 is card on board(3 is player, 4 other side), <y> 0 to 5 is card
// pixel values vec4[EF/HP/AT, ST, COL, ID]

bool save_state(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 ipx = ivec2(fragCoord - 0.5);
    if (max(ipx.x + 5, ipx.y) > 10)return false;
    load_state(fragCoord, true);
    float cards_player = allData.cards_player;
    if (ipx == ivec2(2, 0)) {
        if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
            cards_player = 0.;
            fragColor = vec4(cards_player, 1., g_time, allData.this_selected_card);
            return true;
        }
        float stx = allData.egt + 01.;
        if ((iMouse.z > 0.)&&(1. == SS(stx + 02.5, stx + 2. + 02.5, g_time))&&(allData.flag3 > 0.)) {
            cards_player = 0.;
            fragColor = vec4(cards_player, 0., g_time, allData.this_selected_card);
            return true;
        }
        if (allData.flag1 == 1.)cards_player += -1.;
        else {
            float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
            if ((allData.card_draw > 0.)&&(anim_t2 == 0.)) {
                float anim_t = get_animstate(clamp(1. - (g_time - allData.card_add_anim), 0., 1.));
                if (anim_t == 0.) {
                    cards_player += 1.;
                    if (cards_player > 10.)cards_player = 10.;
                }
            }
        }
        card_get_select(allData.mouse_pos);
        if (cards_player > allData.cards_player)
            fragColor = vec4(cards_player, 1., g_time, allData.this_selected_card);
        else
            if (cards_player < allData.cards_player)
            fragColor = vec4(cards_player, 1., allData.card_add_anim, allData.this_selected_card);
        else
            fragColor = vec4(allData.cards_player, 1., allData.card_add_anim, allData.this_selected_card);
        return true;
    }
    if (ipx == ivec2(2, 1)) {
        float anim_t = get_animstate(clamp(1. - (g_time - allData.card_add_anim), 0., 1.));
        float anim_t2 = 1. - get_animstate(clamp((g_time - allData.card_put_anim - 0.5)*2., 0., 1.));
        float cdr = allData.card_draw;
        if ((allData.flag0 != 1.) || (g_time < extime + 0.1)) {
            cdr = 8.; //draw X cards for players on start
        } else
            if ((anim_t == 0.)&&(anim_t2 == 0.)) {
            cdr += -1.;
            if (cdr < 0.)cdr = 0.;
        }
        if ((cdr == 0.)&&(allData.flag1 == 1.)) {
            vec4 tcx = load_eff_buf();
            if (allData.card_bID_put_anim == 6.)
                if ((int(tcx.w) == c_mn)) {
                    cdr = 2.;
                }
        }
        if ((allData.player_turn)&&(allData.player_etf)) {
            float anim_t2zc = 1. - get_animstate(clamp((g_time - allData.ett - 2.), 0., 1.));
            if (anim_t2zc == 0.) {
                cdr = 1.;
            }
        }
        //reset mouse on new card
        if ((cdr > 0.) || (allData.flag3 == 1.) || (allData.player_etf))
            fragColor = vec4(vec3(0.), cdr);
        else
            fragColor = vec4(allData.mouse_pos, allData.card_select_anim, cdr);
        return true;
    }
    if (ipx == ivec2(2, 2)) {
        if ((allData.flag0 != 1.) || (g_time < extime + 0.1) || (allData.player_etf)) {
            fragColor = vec4(-10.);
            return true;
        }
        if (allData.last_selected_card >= 0.) {
            float anim_t = get_animstate(clamp((g_time - allData.card_select_anim)*2., 0., 1.));
            if (anim_t >= 1.) {
                if (hpmp_get_hit(allData.mouse_pos) > 0) {
                    vec4 tc2 = load_card(int(allData.last_selected_card));
                    if (((hpmp_get_hit(allData.mouse_pos) == 6)&&((int(tc2.w) == c_mn) || (int(tc2.w) == c_he2))) || ((hpmp_get_hit(allData.mouse_pos) == 16)&&(int(tc2.w) == c_at2))) {
                        fragColor = vec4(g_time, allData.last_selected_card, float(hpmp_get_hit(allData.mouse_pos)), 1.);
                    } else {
                        fragColor = vec4(allData.card_put_anim, allData.card_hID_put_anim, allData.card_bID_put_anim, 0.);
                    }
                    return true;
                }
                if (card_get_hit(allData.mouse_pos) >= 0) {
                    int cval = (card_get_hit(allData.mouse_pos) > 9 ? card_get_hit(allData.mouse_pos) - 10 : card_get_hit(allData.mouse_pos));
                    vec4 tc = (card_get_hit(allData.mouse_pos) < 10) ? load_board(cval) : load_board2(cval);
                    vec4 tc2 = load_card(int(allData.last_selected_card));
                    if ((int(tc.w) == c_bgr)&&(is_c_cr(int(tc2.w))&&(card_get_hit(allData.mouse_pos) < 10)))
                        fragColor = vec4(g_time, allData.last_selected_card, float(cval), 1.);
                    else
                        if ((int(tc.w) != c_bgr)&&(is_c_cr(int(tc.w)))&&((int(tc2.w) == c_he1) || (int(tc2.w) == c_at1) || (int(tc2.w) == c_pat) || (int(tc2.w) == c_de)))
                        fragColor = vec4(g_time, allData.last_selected_card, float(card_get_hit(allData.mouse_pos)), 1.);
                    else
                        fragColor = vec4(allData.card_put_anim, allData.card_hID_put_anim, allData.card_bID_put_anim, 0.);
                    return true;
                }
            }
        }
        fragColor = vec4(allData.card_put_anim, allData.card_hID_put_anim, allData.card_bID_put_anim, 0.);
        return true;
    }

    if (ipx == ivec2(2, 3)) {
        effect_buf_logic(fragColor, fragCoord, ipx);
        return true;
    }

    if (ipx == ivec2(2, 4)) {
        hpmp_logic(fragColor, fragCoord, ipx);
        return true;
    }

    for (int i = 0; i < 2; i++)
        for (int j = 0; j < 10; j++) {
            if (ipx == ivec2(i, j)) {
                card_logic(fragColor, fragCoord, ipx);
                return true;
            }
        }
    for (int i = 3; i < 5; i++)
        for (int j = 0; j < 6; j++) {
            if (ipx == ivec2(i, j)) {
                board_logic(fragColor, fragCoord, ipx);
                return true;
            }
        }
    fragColor = vec4(1.);

    return true;
}

#ifdef NOCOMPILE

float text_play(vec2 U) {
    initMsg;C(80);C(76);C(65);C(89);endMsg;
}

float text_playex(vec2 U) {
    initMsg;C(82);C(69);C(65);C(68);C(32);C(67);C(111);C(109);C(109);C(111);C(110);endMsg;
}

float text_playex2(vec2 U) {
    initMsg;C(70);C(79);C(82);C(32);C(76);C(97);C(117);C(110);C(99);C(104);endMsg;
}
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

#ifdef NOCOMPILE
    res_g = res;
    vec2 uv = (fragCoord.xy) / iResolution.y - res_g / 2.0;
    float x = 0.;
    vec3 col = vec3(0.);
    if (iResolution.y > 400.) {
        x = text_play((uv)*1.25 + vec2(res.x, res.y / 4.));
        col = vec3(1.) * x;
        x = text_playex((uv)*5. + vec2(res.x * 2.62, res.y * 2.));
        col += vec3(1., 0., 0.) * x;
        x = text_playex2((uv)*5. + vec2(res.x * 2.63, res.y * 1.2));
        col += vec3(0., 0., 1.) * x;
    } else col = vec3(text_play((uv)*1.25 + vec2(res.x, res.y / 2.)));
    fragColor = vec4(col, 1.);
    return;
#else
    init_globals();
    if (save_state(fragColor, fragCoord))return;
    load_state(fragCoord, false);
    vec2 uv = (fragCoord.xy) / iResolution.y - res_g / 2.0;
    vec4 ret_col = main_c(uv);
    fragColor = ret_col;
#endif
}

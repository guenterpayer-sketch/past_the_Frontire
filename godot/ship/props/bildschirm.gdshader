shader_type spatial;
render_mode unshaded, cull_back;
// Bildschirm auf der Brücke: festes Bild mit leichter Bewegung.
// art 0 = Sternenkarte (pulsierender Ring ums Schiff, Lichtpunkt wandert den Kurs entlang),
// art 1 = Schiffsstatus (Scanlinie über das Schema, Statuspunkte blinken).

uniform sampler2D bild : source_color, filter_linear_mipmap;
uniform int art = 0;
uniform float helligkeit = 1.15;

const vec2 ASPEKT = vec2(1296.0 / 800.0, 1.0);
const vec2 SCHIFF = vec2(480.0 / 1296.0, 290.0 / 800.0);
const vec2 KURS[4] = vec2[](vec2(480.0, 290.0) / vec2(1296.0, 800.0), vec2(720.0, 400.0) / vec2(1296.0, 800.0),
		vec2(870.0, 310.0) / vec2(1296.0, 800.0), vec2(1180.0, 320.0) / vec2(1296.0, 800.0));
const vec3 GOLD = vec3(1.0, 0.75, 0.25);
const float SCHEMA_RAND = 0.68;   // Schema links, Anzeigen rechts

void fragment() {
	vec3 bas = texture(bild, UV).rgb;
	vec3 c = bas;
	if (art == 0) {
		float ph = fract(TIME * 0.5);
		float d = length((UV - SCHIFF) * ASPEKT);
		float ring = smoothstep(0.006, 0.0, abs(d - (0.035 + ph * 0.08))) * (1.0 - ph);
		c += GOLD * ring * 1.2;
		float gesamt = 0.0;
		for (int i = 0; i < 3; i++) {
			gesamt += length((KURS[i + 1] - KURS[i]) * ASPEKT);
		}
		float s = fract(TIME * 0.12) * gesamt;
		vec2 p = KURS[3];
		for (int i = 0; i < 3; i++) {
			float l = length((KURS[i + 1] - KURS[i]) * ASPEKT);
			if (s <= l) {
				p = mix(KURS[i], KURS[i + 1], s / l);
				break;
			}
			s -= l;
		}
		c += GOLD * smoothstep(0.018, 0.0, length((UV - p) * ASPEKT)) * 1.5;
	} else if (UV.x < SCHEMA_RAND && UV.y > 0.1 && UV.y < 0.92) {
		// Statuspunkte (grün) blinken
		if (bas.g > 0.4 && bas.r < 0.3 && bas.b < 0.3) {
			c *= 0.7 + 0.4 * (0.5 + 0.5 * sin(TIME * 3.0));
		}
		float x = fract(TIME * 0.12) * SCHEMA_RAND;
		c += vec3(0.25, 0.55, 1.0) * smoothstep(0.012, 0.0, abs(UV.x - x)) * 0.5;
	}
	ALBEDO = c * helligkeit;
}

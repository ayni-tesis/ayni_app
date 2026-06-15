# Design

## Theme

Mobile-first utility interface para uso en campo. La claridad y la velocidad de lectura son más importantes que la expresion visual. Superficies neutras con acentos verdes de marca. Sin decoration innecesaria.

## Color Palette

### Brand Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-primary` | `#04A033` | Botón de captura, acciones principales, indicador de éxito de diagnóstico |
| `--color-secondary` | `#DDFFE7` | Fondos sutiles, badges de estado positivo, highlights |

### State Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-info` | `#C2BFBF` | Estados neutros, disabled |
| `--color-success` | `#27AE60` | Diagnóstico de hoja sana, sincronización exitosa |
| `--color-warning` | `#E2B93B` | Diagnóstico con confianza media (60-84%), indicador offline |
| `--color-error` | `#EB5757` | Diagnóstico de plaga, errores, confianza baja (<60%) |

### Neutrals

| Token | Hex | Usage |
|---|---|---|
| `--color-black-1` | `#000000` | Texto de máxima prioridad |
| `--color-black-2` | `#1D1D1D` | Encabezados |
| `--color-black-3` | `#282828` | Subtítulos, labels |
| `--color-gray-1` | `#333333` | Body text principal |
| `--color-gray-2` | `#4F4F4F` | Body text secundario |
| `--color-gray-3` | `#828282` | Placeholder, hints |
| `--color-gray-4` | `#BDBDBD` | Borders sutiles, dividers |
| `--color-gray-5` | `#E0E0E0` | Backgrounds de cards, inputs |
| `--color-white` | `#FFFFFF` | Fondo principal de la app |

## Typography

**Font Family:** Nunito (Google Fonts) — única fuente del proyecto.

### Type Scale

| Style | Font Size | Line Height | Weight | Usage |
|---|---|---|---|---|
| Heading 1 | 56px | 61.6px | 700 | — |
| Heading 2 | 48px | 52.8px | 700 | — |
| Heading 3 | 40px | 44px | 700 | — |
| Heading 4 | 32px | 35.2px | 700 | Títulos de sección en dashboard |
| Heading 5 | 24px | 26.4px | 700 | — |
| Heading 6 | 20px | 22px | 700 | — |
| Large Text Bold | 20px | 28px | 700 | — |
| Large Text Regular | 20px | 28px | 400 | — |
| Medium Text Bold | 18px | 25.2px | 700 | — |
| Medium Text Regular | 18px | 25.2px | 400 | — |
| Body Bold | 16px | 22.4px | 700 | Labels, acciones |
| Body Regular | 16px | 22.4px | 400 | Texto principal |
| Small Text Bold | 14px | 19.6px | 700 | Badges, metadata |
| Small Text Regular | 14px | 19.6px | 400 | Texto auxiliar |

**Line height ratio:** 1.1× para headings, 1.4× para body.

## Spacing

Escala base de 8px.

| Token | Value |
|---|---|
| `--space-s1` | 8px |
| `--space-s2` | 16px |
| `--space-s3` | 24px |
| `--space-s4` | 32px |
| `--space-s5` | 40px |
| `--space-s6` | 56px |
| `--space-s7` | 72px |
| `--space-s8` | 80px |
| `--space-s9` | 96px |
| `--space-s10` | 120px |

## Iconography

- **Library:** Lucide Icons (Flutter: `lucide_icons`; Web: `lucide-react`)
- **Size:** 24px full size, 20px live area, 2px save area
- **Style:** Outline como default; Fill para estados activos/seleccionados
- **Tap target mínimo:** 48×48dp

## Grid

Responsive con breakpoints:

| Device | Width | Columns | Column Width | Gutter |
|---|---|---|---|---|
| Mobile | 320px | 2 | 130px | — |
| Tablet | 768px | 6 | 88px | — |
| Desktop | 1024px | 12 | 50px | — |
| Desktop HD | 1440px | 12 | 90px | — |

La app móvil usa principalmente 2-6 columnas. El dashboard web usa 12 columnas.

## Component Guidelines

### Buttons

- **Tap target mínimo:** 48×48dp
- **Botón de captura:** 72×72dp mínimo, color primario, icono camera_alt 32px
- **Variantes:** Primary (filled `--color-primary`), Secondary (outlined), Danger (filled `--color-error`)
- **Border radius:** 12px para buttons estándar, full-pill para badges/tags

### Inputs / Textfields

- **Height:** 48px mínimo
- **Border:** 1px `--color-gray-4`, focus: 2px `--color-primary`
- **Border radius:** 12px
- **Placeholder:** `--color-gray-3` (no usar gray-4 o gray-5, no pasan contraste 4.5:1)

### Cards

- **Background:** `--color-white`
- **Border:** 1px `--color-gray-5` o shadow sutil (max 8px blur, no border + shadow juntos)
- **Border radius:** 12-16px
- **Padding:** `--space-s3` (24px) interno

### Confidence Bar

- Height: 8px
- Border radius: 4px (full-rounded en narrow widths)
- Colores por rango:
  - ≥85%: `--color-success`
  - 60-84%: `--color-warning`
  - <60%: `--color-error`

### Pest Badge

- Pill shape (full border-radius)
- Background según plaga:
  - Roya: `--color-error` tint
  - Minador: `--color-warning` tint
  - Phoma: `--color-gray-2` tint
  - Sana: `--color-success` tint

### Offline Indicator

- Banner fixed en la parte superior de la pantalla
- Background: `--color-warning`
- Icono: `cloud_off`
- Texto: "Sin conexión — diagnósticos guardados localmente"

## Motion

- **Easing:** ease-out-quart para entradas, ease-in para salidas
- **Duración:** 200-300ms para micro-interacciones, 400ms para transiciones de pantalla
- **Reduced motion:** cumplir `prefers-reduced-motion` — usar crossfade en vez de slide/fade

## Shadows

| Level | Value | Usage |
|---|---|---|
| sm | `0 1px 2px rgba(0,0,0,0.06)` | Inputs, cards sutiles |
| md | `0 4px 8px rgba(0,0,0,0.08)` | Cards elevados, dropdowns |
| lg | `0 8px 16px rgba(0,0,0,0.10)` | Modals, toasts |

No usar shadow + border en el mismo elemento.

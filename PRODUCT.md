# Product

## Register

product

## Users

**Caficultores de Villa Rica** (Oxapampa, Pasco, Perú) que trabajan en campo con conectividad limitada. usuarios con posible baja alfabetización digital, que usan la app bajo luz solar directa y frecuentemente con guantes de trabajo.

**Usuarios secundarios:** Administradores e investigadores del dashboard web que gestionan el dataset, validan diagnósticos y generan reportes fitosanitarios para SENASA.

## Product Purpose

AYNI es una aplicación móvil (Android) de detección temprana de plagas en hojas de café mediante visión computacional y aprendizaje automático con enfoque offline-first. El caficultor captura una foto de la hoja y recibe en segundos el tipo de plaga, nivel de confianza y recomendación de tratamiento. Cuando no hay conexión, el diagnóstico se ejecuta localmente con el modelo TFLite y se sincroniza cuando se recupera señal.

**Trabajo primario en la app:** capturar una foto → obtener diagnóstico → decidir acción.

## Brand Personality

- **Confianza técnica accesible:** el rigor de un agrónomo en palabras simples de caficultor.
- **Terreno y confiable:** nada de marketing, solo valor funcional inmediato.
- **Claro bajo presión:** resultados legibles bajo sol, con dedos torpes, sin internet.

## Anti-references

- No es una app de productividad general — no tiene dashboard, no tiene charts complejos en campo.
- No usar colores corporativos azul/gris genéricos de SaaS.
- No usar gradientes decorativos ni glassmorphism.
- No usar jerga técnica en la UI — "Roya" no "Hemileia vastatrix".
- No diseñar para desktop ni para usuarios expertos — el caficultor es el usuario primario.

## Design Principles

1. **Diagnóstico en una pantalla.** El resultado del análisis cabe sin scroll. El botón de captura es el elemento dominante.
2. **Funciona sin internet.** La UI nunca bloquea ni confunde al usuario cuando no hay conexión. El estado offline es primero, no una excepción.
3. **Legibilidad en campo.** Contraste alto, textos grandes, iconografía clara, mínimo tap 48×48 dp.
4. **Recomendación accionable.** Cada diagnóstico incluye una recomendación concreta, no solo un dato.
5. **El modelo mejora con el usuario.** Las imágenes validadas retroalimentan el dataset — el caficultor es parte del sistema.

## Accessibility & Inclusion

- Contraste mínimo WCAG AA (4.5:1 para texto normal, 3:1 para texto grande).
- Tamaño de tap mínimo 48×48 dp (usuarios con guantes).
- Sin animación excesiva — reducir movimiento en `prefers-reduced-motion`.
- Texto en español peruano simple — lectura para cualquier nivel de alfabetización digital.
- Soporte paramodo oscuro via `ThemeMode.system`.

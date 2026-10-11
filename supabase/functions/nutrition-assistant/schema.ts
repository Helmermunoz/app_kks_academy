export const proposalSchema = {
  type: 'object', additionalProperties: false,
  required: ['meals', 'hydration', 'recovery', 'review_warning'],
  properties: {
    meals: {type: 'array', minItems: 1, maxItems: 6, items: {
      type: 'object', additionalProperties: false,
      required: ['suggestion', 'timing'],
      properties: {suggestion: {type: 'string', maxLength: 600}, timing: {type: 'string', maxLength: 300}},
    }},
    hydration: {type: 'string', maxLength: 800},
    recovery: {type: 'string', maxLength: 800},
    review_warning: {type: 'string', maxLength: 800},
  },
};
export type Proposal = {meals: {suggestion: string; timing: string}[]; hydration: string; recovery: string; review_warning: string};
export function validateProposal(value: unknown): Proposal {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error('invalid_output');
  const p = value as Record<string, unknown>;
  if (Object.keys(p).sort().join() !== 'hydration,meals,recovery,review_warning') throw Error('invalid_output');
  const text = (v: unknown, max: number) => typeof v === 'string' && v.trim().length > 0 && v.length <= max;
  if (!text(p.hydration,800) || !text(p.recovery,800) || !text(p.review_warning,800) ||
    !Array.isArray(p.meals) || p.meals.length < 1 || p.meals.length > 6 || p.meals.some(m =>
      !m || typeof m !== 'object' || Object.keys(m).sort().join() !== 'suggestion,timing' ||
      !text(m.suggestion,600) || !text(m.timing,300))) throw Error('invalid_output');
  return p as Proposal;
}
export const mockProposal: Proposal = {
  meals: [{suggestion: 'EJEMPLO: el profesional seleccionará alimentos tras revisar las restricciones.', timing: 'Revisar el horario con el profesional.'}],
  hydration: 'EJEMPLO: mantener agua disponible durante la actividad; sin cantidades prescritas.',
  recovery: 'EJEMPLO: reservar tiempo para descansar después del entrenamiento.',
  review_warning: 'BORRADOR DE PRUEBA. No es un plan de alimentación y no puede aprobarse.',
};

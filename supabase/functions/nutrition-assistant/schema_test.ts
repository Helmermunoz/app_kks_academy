import {mockProposal,validateProposal} from './schema.ts';
const assert = (ok: boolean) => {if (!ok) throw Error('Assertion failed');};
Deno.test('mock is valid, recognizable and non-personalized', () => {
  assert(validateProposal(mockProposal).review_warning.includes('PRUEBA'));
});
Deno.test('reject malformed, extra, missing and oversized output', () => {
  for (const value of [null,[],{}, {...mockProposal, extra:'x'}, {...mockProposal, meals:[]},
    {...mockProposal, hydration:'x'.repeat(801)}, {...mockProposal, meals:[{suggestion:'x',timing:3}]}]) {
    let failed = false; try {validateProposal(value);} catch {failed = true;} assert(failed);
  }
});

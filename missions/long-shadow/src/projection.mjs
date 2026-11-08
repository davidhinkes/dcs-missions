// WGS84 transverse Mercator with the DCS Syria terrain parameters (as used by
// pydcs): central meridian 39E, k0 0.9996, false easting 282801 m, false
// northing -3879866 m. DCS planar x is north, mission y is east. Offline
// conversion only: a converted point is not a terrain/road check in DCS.
const a=6378137,f=1/298.257223563,e2=f*(2-f),ep2=e2/(1-e2),k0=0.9996;
const lon0=39*Math.PI/180,FE=282801.00000003993,FN=-3879865.9999999935;
const meridian=phi=>a*((1-e2/4-3*e2**2/64-5*e2**3/256)*phi-(3*e2/8+3*e2**2/32+45*e2**3/1024)*Math.sin(2*phi)
  +(15*e2**2/256+45*e2**3/1024)*Math.sin(4*phi)-(35*e2**3/3072)*Math.sin(6*phi));
export function toDcs({lat,lon}){
  const phi=lat*Math.PI/180,l=lon*Math.PI/180;
  const N=a/Math.sqrt(1-e2*Math.sin(phi)**2),T=Math.tan(phi)**2,C=ep2*Math.cos(phi)**2,A=(l-lon0)*Math.cos(phi);
  const east=k0*N*(A+(1-T+C)*A**3/6+(5-18*T+T*T+72*C-58*ep2)*A**5/120);
  const north=k0*(meridian(phi)+N*Math.tan(phi)*(A*A/2+(5-T+9*C+4*C*C)*A**4/24+(61-58*T+T*T+600*C-330*ep2)*A**6/720));
  return {x:north+FN,y:east+FE};
}
/** Cockpit-style degrees and decimal minutes, e.g. N34 52.680 E036 32.520. */
export function dm({lat,lon}){
  const part=(v,pos,neg,w)=>{const d=Math.floor(Math.abs(v)),m=(Math.abs(v)-d)*60;return `${v>=0?pos:neg}${String(d).padStart(w,'0')} ${m.toFixed(3).padStart(6,'0')}`;};
  return `${part(lat,'N','S',2)} ${part(lon,'E','W',3)}`;
}

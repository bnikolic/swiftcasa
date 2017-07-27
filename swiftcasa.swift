/* -*- mode: c; -*- */
/* Main SWIFT module for supporting use of CASA */


import io;
import python;
import unix;

app (file o) noop()
{
  "true" o;
}

app (file o) cpr(file i)
{
  "cp" "-r" i o;
}

(file vis) casa_importuvfits(file uv)
{
  vis=noop();
  python_persist("import os; os.remove('%s'); import casa; casa.importuvfits('%s', '%s'); " %
		 (filename(vis), filename(uv), filename(vis)));
}

(file ovis) casa_flagdata(file vis, string mode="", string antenna="", string spw="",
      	    		  boolean autocorr=false)
{
  // vis has to be filled before calling the CASA task. STC does not seem
  // to pick this up
  wait(vis) {
    ovis=vis;    
    python_persist("import casa; casa.flagdata('%s', flagbackup=True, mode='%s', antenna='%s', spw='%s', autocorr=bool(%b)); " %
		   (filename(ovis), mode, antenna, spw, autocorr));
  }
}

/* Create a component list with a single component, e.g., for use in
   initialising the calibration process
 */
(file omodel) mkinitmodel(string direction, float flux, string shape="point", string fluxunit="Jy")
{
  omodel=noop();
  python_persist("""
f='%s';
import os;
if(os.path.exists(f)):
   os.remove(f)
import casac;
cl=casac.casac.componentlist();
cl.addcomponent(flux=%f,
                fluxunit='%s',
                shape='%s',
                dir='%s')
cl.rename('%s')
cl.close()
""" %
		 (filename(omodel), flux, fluxunit, shape, direction, filename(omodel)));
}


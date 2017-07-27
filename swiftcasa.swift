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

(file ovis) casa_ft(file vis, file complist, boolean usescratch=true)
{
  wait(vis) {
    ovis=vis;
    python_persist("import casa; casa.ft('%s', complist='%s', usescratch=bool(%b));" %
		   (filename(ovis), filename(complist), usescratch));
  }
}

/* Basic gaincal,
   no support yet for caltables
*/
(file ocal) casa_gaincal(file vis, file gaintable[],
			 string gaintype="", string solint="",
			 string refant="", float minsnr=1.0,
			 string spw="" )
{
  ocal=noop();
  wait(vis) {
    wait(gaintable) {
    python_persist("""
import os; os.remove('%s');
import casa;
casa.gaincal('%s', caltable='%s',
             gaintype='%s', solint='%s', refant='%s',
             minsnr=%f, spw='%s');
""" %
		   (filename(ocal),
		    filename(vis), filename(ocal),
		    gaintype, solint, refant,
		    minsnr, spw
		    ));
    }
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
import os; import shutil;
if(os.path.exists(f)):
   if (os.path.isdir(f)):
      shutil.rmtree(f)
   else:
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


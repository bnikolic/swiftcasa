/* -*- mode: c; -*- */
/* Main SWIFT module for supporting use of CASA */

/* Rules for binding
- Always python_persist (CASA loads numpy, which can not be re-initialised)
- wait [deep] on all file inputs to CASA task (SWIFT/T can not see inside)
 */


import io;
import python;
import unix;
import string;

app (file o) noop()
{
  "true" o;
}

app (file o) noop2(string x)
{
  "true" o x;
}

app (file o) cpr(file i)
{
  "cp" "-r" i o;
}

(string o) python_filelist(file i[])
{
  string x[];
  foreach v,dx in i
  {
    x[dx]="'"+filename(v)+"'";
  }
  o=sprintf("[%s]", join(x, ", "));
}


(file vis) casa_importuvfits(file uv)
{
  wait(uv) {
    vis=noop2(python_persist("import os; os.remove('%s'); import casa; casa.importuvfits('%s', '%s'); " %
                            (filename(vis), filename(uv), filename(vis))));
  }
}

(file ovis) casa_flagdata(file vis, string mode="", string antenna="", string spw="",
                          boolean autocorr=false)
{
  // vis has to be filled before calling the CASA task. STC does not seem
  // to pick this up
  wait(vis) {
    python_persist("import casa; casa.flagdata('%s', flagbackup=True, mode='%s', antenna='%s', spw='%s', autocorr=bool(%b)); " %
                         (filename(vis), mode, antenna, spw, autocorr))=>
    ovis=vis;
  }
}

(file ovis) casa_ft(file vis, file complist, boolean usescratch=true)
{
  wait(vis, complist) {
    python_persist("import casa; casa.ft('%s', complist='%s', usescratch=bool(%b));" %
                         (filename(vis), filename(complist), usescratch))=>
    ovis=vis;
  }
}

/* Basic gaincal
*/
(file ocal) casa_gaincal(file vis, file gaintable[],
                         string gaintype="", string solint="",
                         string refant="", float minsnr=1.0,
                         string spw="", string calmode="" )
{
  wait(vis) {
    wait deep (gaintable) {
      ocal=noop2(python_persist("""
import os; os.remove('%s');
import casa;
casa.gaincal('%s', caltable='%s',
             gaintable=%s,
             gaintype='%s', solint='%s', refant='%s',
             minsnr=%f, spw='%s', calmode='%s');
""" %
                   (filename(ocal),
                    filename(vis), filename(ocal),
                    python_filelist(gaintable),
                    gaintype, solint, refant,
                    minsnr, spw, calmode
                    )));
    }
  }
}

(file ovis) casa_applycal(file vis, file gaintable[])
{
  wait(vis) {
    wait deep (gaintable) {
      python_persist("""
import casa;
casa.applycal('%s',
             gaintable=%s);
""" %
                   (filename(vis),
                    python_filelist(gaintable))) =>
    ovis=vis;
    }
  }
}

(file ovis) casa_split(file vis, string datacolumn="corrected", string spw="")
{
  wait(vis) {
    ovis=noop2(python_persist("""
import os; os.remove('%s');
import casa;
casa.split('%s', '%s', datacolumn='%s', spw='%s');
""" % (filename(ovis), filename(vis),
       filename(ovis), datacolumn, spw)));
  }
}

/* CLEAN has multiple outputs (restored image, clean comps, etc) hence
   the output is to a directory 
*/
(file oimgdir) casa_clean(file vis, int niter,
			  int imsize[],
			  string cell,
			  string spw,
			  string mask,
			  string weighting="briggs",
			  float robust=0,
			  string mode="mfs",
			  int nterms=1)
{
  wait(vis) {
  oimgdir=noop2(
python_persist("""
f='%s';
import os; import shutil;
if(os.path.exists(f)):
   if (os.path.isdir(f)):
      shutil.rmtree(f)
   else:
      os.remove(f)
os.mkdir(f)
import casa
casa.clean(vis='%s', imagename='%s/img', niter=%i,
           weighting='%s', robust=%f,
           imsize=[%i,%i],
           cell=['%s'],
           mode='%s',
           nterms=%i,
           spw='%s',
           mask='%s');
"""%
   (filename(oimgdir),
    filename(vis),
    filename(oimgdir),
    niter, weighting, robust, imsize[0], imsize[1],
    cell, mode, nterms, spw, mask)));

}}

(file oplot) casa_viewer(file img, string extn)
{
  wait (img) {
  oplot=noop2(
python_persist("""
f='%s';
import os; import shutil;
if(os.path.exists(f)):
   if (os.path.isdir(f)):
      shutil.rmtree(f)
   else:
      os.remove(f)
import casa
casa.viewer(infile='%s',
       outfile='%s',
       gui=False,
       outformat='png')
import task_viewer
task_viewer.ving.done()
import psutil
current_process = psutil.Process()
children = current_process.children(recursive=True)
for child in children:
    child.kill()
"""%
   (filename(oplot),
    filename(img)+"/img"+extn,
    filename(oplot)
    )));
  }
}


/* Create a component list with a single component, e.g., for use in
   initialising the calibration process
 */
(file omodel) mkinitmodel(string direction, float flux, string shape="point", string fluxunit="Jy")
{
  omodel=noop2(
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
                 (filename(omodel), flux, fluxunit, shape, direction, filename(omodel))));
}


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

(void a) close_file(file f) "turbine" "0.0.2" "close_file";

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

(string o) python_intlist(int i[])
{
  string x[];
  foreach v,dx in i
  {
    x[dx]=int2string(v);
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

(file ovis) casa_fixvis(file vis, string phasecntr)
{
  wait(vis) {
    python_persist("import casa; casa.fixvis('%s', '%s', phasecenter='%s'); " %
		   (filename(vis), filename(vis) , phasecntr))=>
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

(file ocal) casa_bandpass(file vis, file gaintable[],
			  string bandtype="",
			  boolean solnorm=false,
			  float minsnr=1.0 )
{
  wait(vis) {
    wait deep (gaintable) {
      ocal=noop2(python_persist("""
import os; os.remove('%s');
import casa;
casa.bandpass('%s', caltable='%s',
              gaintable=%s,
              bandtype='%s', 
              minsnr=%f, 
              solnorm=bool(%b)
              );
""" %
                   (filename(ocal),
                    filename(vis), filename(ocal),
                    python_filelist(gaintable),
                    bandtype, minsnr,
		    solnorm)));
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

(file ovis) casa_split(file vis, string datacolumn="corrected", string spw="", string timebin="")
{
  wait(vis) {
    ovis=noop2(python_persist("""
import os; os.remove('%s');
import casa;
casa.split('%s', '%s', datacolumn='%s', spw='%s', timebin='');
""" % (filename(ovis), filename(vis),
       filename(ovis), datacolumn, spw, timebin)));
  }
}

/* CLEAN has multiple outputs (restored image, clean comps, etc) hence
   the output is to a directory.
   
   vis is an array of visibility files to include into clean
*/
(file oimgdir) casa_clean(file vis[],
			  int niter,
			  int imsize[],
			  string cell,
			  string spw,
			  string mask,
			  string weighting="briggs",
			  float robust=0,
			  string mode="mfs",
			  int nterms=1)
{
  wait deep (vis) {
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
casa.clean(vis=%s, imagename='%s/img', niter=%i,
           weighting='%s', robust=%f,
           imsize=[%i,%i],
           cell=['%s'],
           mode='%s',
           nterms=%i,
           spw='%s',
           mask='%s');
"""%
   (filename(oimgdir),
    python_filelist(vis),
    filename(oimgdir),
    niter, weighting, robust, imsize[0], imsize[1],
    cell, mode, nterms, spw, mask)));

}}

(file oplot) casa_viewer(file img, string extn)
{
  wait (img) {
    file oplot_t=mktemp() =>
    x=python_persist("""
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
# CASA  will always remove the extension and replace with .png
shutil.move(os.path.splitext(f)[0] + '.png', f)
import psutil
current_process = psutil.Process()
children = current_process.children(recursive=True)
for child in children:
    child.kill()
if (not os.path.exists(f)):
   print f
   raise ValueError('Output file not found!')
"""%
   (filename(oplot_t),
    filename(img)+"/img"+extn,
    filename(oplot_t)
    , "repr(1)"));
    wait (x) {
      oplot=oplot_t;
    }
  }
}

(string res) casa_vishead(file vis, string hdkey)
{
  wait(vis){
    res=python_persist("""
import casa;
r=casa.vishead(vis='%s',
       hdkey='%s',
       mode='get');
""" %
(filename(vis), hdkey), "repr(r[0]['r1'])");
  }
}

(file ofits)  casa_exportfits(file infits)
{
  wait(infits){
    file ofits_t=mktemp() =>
    python_persist("""
f='%s';
import os; import shutil;
if(os.path.exists(f)):
   if (os.path.isdir(f)):
      shutil.rmtree(f)
   else:
      os.remove(f)
import casa;
r=casa.exportfits('%s','%s');
""" %
		   (filename(ofits_t), filename(infits), filename(ofits_t))) =>
    ofits=ofits_t;
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

(file ovis) adduvw(file ivis, string calname)
{
  wait(ivis)
  {
    file ovis_t=mktemp() =>
    python_persist("import heracasa.data.uvconv as uvconv; uvconv.add_uvw('%s', '%s', '%s')" %
		   (filename(ivis), filename(ovis) ,calname)) =>
    ovis=ovis_t;
  }
}

(file ovis) cvuvfits(file ivis)
{
  wait(ivis)
  {
    file ovis_t=mktemp() =>
    python_persist("import heracasa.data.uvconv as uvconv; uvconv.cvuvfits('%s', '%s')" %
		   (filename(ivis), filename(ovis))) =>
    ovis=ovis_t;
  }
}


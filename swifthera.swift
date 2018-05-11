/* -*- mode: c; -*- */
/* SWIFT wrapper functions supporting HERA data reduction */

import swiftcasa;

(file ovis) bn_reorder(file vis)
{
  wait(vis) {
    python_persist("import clplot.clquants as clquants; clquants.reorrder('%s');  " %
		   (filename(vis)))=>
    ovis=vis;
  }
}

(file ofile) bn_cclosure(file vis, int antenna[])
{
  wait(vis)
  {
    file ofile_t=mktemp() =>
      python_persist("heracasa.closure as cc; import numpy; r=cc.closurePh('%s', %s); numpy.savez('%s')"%
		     (filename(vis), python_intlist(antenna), filename(ofile_t)))    =>
      ofile=ofile_t;
  }
}

(file ofile) bn_flat2hpx(file ifile[])
{
  wait(ifile)
  {
    file ofile_t=mktemp() =>
      python_persist("""
import os; os.remove('%s');
import heracasa.data.img as ii; ii.flat2hpx(%s, '%s')
"""%
		     (filename(ofile_t), python_filelist(ifile), filename(ofile_t)))    =>
      ofile=ofile_t;
  }
}

(file oplot) bn_hpplot(file ifile, float dmin, float dmax)
{
  wait(ifile)
  {
    file ofile_t=mktemp() =>
      python_persist("""
import matplotlib;
matplotlib.use('Agg');
import os; os.remove('%s');
import heracasa.plot.viewer as viewer; 
viewer.hpplot('%s', '%s', %f, %f)
"""%
		     (filename(ofile_t), filename(ifile), filename(ofile_t),
		      dmin, dmax))    =>
      oplot=ofile_t;
  }
}

(file oplot) bn_viewer(file img, string extn, float dmin, float dmax)
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
import heracasa.plot.viewer as viewer
viewer.viewer(infile='%s',
       outfile='%s',
       plotrange=[%f, %f])
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
""" %
   (filename(oplot_t),
    filename(img)+"/img"+extn,
    filename(oplot_t),
    dmin, dmax   , "repr(1)"));
    wait (x) {
      oplot=oplot_t;
    }
  }
}

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

(file ovis) casa_flagdata(file vis, string mode, string antenna, string spw="")
{
  // vis has to be filled before calling the task. STC does not seem
  // to pick this up
  wait(vis) {
    ovis=vis;    
    python_persist("import casa; casa.flagdata('%s', flagbackup=True, mode='%s', antenna='%s', spw='%s'); " %
		   (filename(ovis), mode, antenna, spw));
  }
}


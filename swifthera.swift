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


#!/bin/bash
#
# Copyright(C) 2008, 2009 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#
   CONFIG=$1
   ADVISDIR=$2
   STORM=$3
   YEAR=$4
   ADVISORY=$5
   HOSTNAME=$6
   ENSTORM=$7
   CSDATE=$8
   HSTIME=$9
   GRIDFILE=${10}
   OUTPUTDIR=${11}
   SYSLOG=${12}
   #
   . ${CONFIG} # grab all static config info
   #
   # grab storm class and name from file
   STORMNAME=`cat nhcClassName` 
   STORMNAME=${STORMNAME}" "${YEAR}
   # transpose elevation output file so that we can graph it with gnuplot
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${ADVISDIR}/${ENSTORM}/fort.15 --stationfile ${ADVISDIR}/${ENSTORM}/fort.61 --format space --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english
   # transpose wind velocity output file so that we can graph it with gnuplot
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose windvelocity --controlfile ${ADVISDIR}/${ENSTORM}/fort.15 --stationfile ${ADVISDIR}/${ENSTORM}/fort.72 --format space --vectorOutput magnitude --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english
   # now create csv files that can easily be imported into excel
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${ADVISDIR}/${ENSTORM}/fort.15 --stationfile ${ADVISDIR}/${ENSTORM}/fort.61 --format comma --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose windvelocity --controlfile ${ADVISDIR}/${ENSTORM}/fort.15 --stationfile ${ADVISDIR}/${ENSTORM}/fort.72 --format comma --vectorOutput magnitude --coldstartdate $CSDATE --gmtoffset -5 --timezone CDT --units english
   # 
   # switch to plots directory
   initialDirectory=`pwd`;
   mkdir ${ADVISDIR}/${ENSTORM}/plots
   mv *.txt *.csv ${ADVISDIR}/$ENSTORM/plots
   cd ${ADVISDIR}/$ENSTORM/plots
   # plot elevation data with gnuplot
   perl ${OUTPUTDIR}/autoplot.pl --filetoplot fort.61_transpose.txt --plotType elevation --plotdir ${ADVISDIR}/${ENSTORM}/plots --outputdir ${OUTPUTDIR} --timezone CDT --units english --stormname "$STORMNAME" --enstorm $ENSTORM --advisory $ADVISORY --datum NAVD88
   # plot wind speed data with gnuplot 
   perl ${OUTPUTDIR}/autoplot.pl --filetoplot fort.72_transpose.txt --plotType windvelocity --plotdir ${ADVISDIR}/${ENSTORM}/plots --outputdir ${OUTPUTDIR} --timezone CDT --units english --stormname "$STORMNAME" --enstorm $ENSTORM --advisory $ADVISORY --datum NAVD88
   for plotfile in `ls *.gp`; do
      gnuplot $plotfile
   done
   for plotfile in `ls *.ps`; do
      pngname=${plotfile%.ps}.png
      ${IMAGEMAGICKPATH}/convert -rotate 90 $plotfile $pngname
   done
   tar cvzf ${ADVISDIR}/${ENSTORM}/${YEAR}${STORM}.${ADVISORY}.plots.tar.gz *.png *.csv
   cd $initialDirectory
#
# FigGen32.exe (called below) calls the 'convert' program, and the path is 
# not configurable there, so let's see if we can get the program to work
# by adding the imagemagick path to the path before calling that program
export PATH=$PATH:$IMAGEMAGICKPATH 
#
#  now create the Google Earth, jpg, and GIS output files
   ${OUTPUTDIR}/POSTPROC_KMZGIS/POST_SCRIPT.sh $ADVISDIR $OUTPUTDIR $STORM $YEAR $ADVISORY $HOSTNAME $ENSTORM $GRIDFILE 

# -----------------------------------
# RANGER SPECIFIC
# ----------------------------------

#  now copy the files to the appropriate locations
      OUTPUTPREFIX1=${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}-KMZ_GIS
      OUTPUTPREFIX2=${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}-plots
    mv  ${ADVISDIR}/${ENSTORM}/${YEAR}${STORM}.${ADVISORY}.plots.tar.gz ${ADVISDIR}/${ENSTORM}/$OUTPUTPREFIX2.tar.gz

      if  [! -d  $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}]
       then
      mkdir  $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}
        chmod 766 $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}
      fi
      cp $OUTPUTPREFIX1.tar.gz $OUTPUTPREFIX2.tar.gz fort.22 fort.22.meta $ADVISDIR/al${STORM}${YEAR}.fst $ADVISDIR/bal${STORM}${YEAR}.dat fort.61 maxele.63 maxwvel.63 $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/

 #    tar -xzf $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/$OUTPUTPREFIX1.tar.gz -C $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/
 #    mv $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/${OUTPUTPREFIX1}_files/* $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/
 #    rmdir $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/${OUTPUTPREFIX1}_files

       chmod 644  $DATAPOSTDIR/${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}/*

 #
    ${OUTPUTDIR}/scp_files_ranger.exp ${OUTPUTDIR} $ADVISDIR $RESULTSHOST $RESULTSPATH $RESULTSPROMPT $RESULTSUSER $RESULTSPASSWORD $HOSTNAME $ENSTORM $OUTPUTPREFIX1 $OUTPUTPREFIX2 > scp.log &

    sleep 60

# now create a timeseries animation KMZ
#  cd $POSTPROC_DIR/TimeseriesKMZ/
#
#    ln -fs $INPUTFILE ./
#    ln -fs $ADVISDIR/$ENSTORM/fort.14 ./
#    ln -fs $ADVISDIR/$ENSTORM/fort.63 ./
#    ln -fs $ADVISDIR/$ENSTORM/fort.74 ./
#
#  perl make_JPG.pl --outputdir $POSTPROC_DIR --gmthome $GMTHOME --storm ${STORM} --year ${YEAR} --adv $ADVISORY --n $NORTH --s $SOUTH --e $EAST --w $WEST --outputprefix $OUTPUTPREFIX
#
#     ${OUTPUTDIR}/POSTPROC_KMZGIS/TimeseriesKMZ/

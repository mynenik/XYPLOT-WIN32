// CPlotDisplay.cpp
//
// Copyright 1996--2020 Krishna Myneni
//
// This software is provided under the terms of the
// GNU Affero General Public License (AGPL) v 3.0 or later.
//
#include "stdafx.h"
#include <fstream>
#include <vector>
#include <deque>
using namespace std;
#include "CDataset.h"
#include "CTransform.h"
#include "CPlotObject.h"
#include "CPlot.h"
#include "CPlotList.h"
#include "CGrid.h"
#include "CPolarGrid.h"
#include "CXyPlot.h"
#include "xyp41.h"
#include "CWorkspace41.h"
#include "CPlotView.h"
#include "CPlotDisplay.h"
#include <string.h>
extern char* DisplayFormat (float, float);

//---------------------------------------------------------------

CPlotDisplay::CPlotDisplay()
{
    m_fAspect = 1.;
    m_pPlotList = new CPlotList();
    vector<float> x(4);
    x[0] = -1.;
    x[1] = 1.;
    x[2] = -1.;
    x[3] = 1.;
    CreateView (CARTESIAN, x);
}
//---------------------------------------------------------------

CPlotDisplay::~CPlotDisplay()
{
    m_qPV.erase(m_qPV.begin(), m_qPV.end());
    delete m_pPlotList;
}
//---------------------------------------------------------------

void CPlotDisplay::SetCoordinateDisplayFormat(vector<float> x)
{
    strcpy (m_szXform, DisplayFormat(x[0],x[1]));
    strcpy (m_szYform, DisplayFormat(x[2],x[3]));
}
//---------------------------------------------------------------

void CPlotDisplay::CreateView(COORDINATE_SYSTEM cdns, vector<float> x)
{
    CPlotView* pv = new CPlotView(cdns, x);
    if (pv) {
      m_qPV.push_back(pv);
      this->SetCoordinateDisplayFormat(x);    
      if (m_qiView >= m_qPV.begin()) {
        // new plot view inherits some properties from previous view
        bool bXlines, bYlines, bXaxes, bYaxes;
        (*m_qiView)->m_pGrid->GetLines(&bXlines, &bYlines);
        (*m_qiView)->m_pGrid->GetAxes(&bXaxes, &bYaxes);
        pv->m_pGrid->SetLines(bXlines, bYlines);
        pv->m_pGrid->SetAxes(bXaxes, bYaxes);
      }
    }
    m_qiView = m_qPV.end() - 1;
}
//---------------------------------------------------------------
/*
void CPlotDisplay::SetViewAngles(float theta, float phi)
{
	float angles[2] = {theta, phi};
	m_pCt->SetView(angles);
}
*/
//---------------------------------------------------------------

void CPlotDisplay::SetPlotRect (CRect wRect, CDC* pDC)
{
// Input rectangle is the entire client area to be used
//   for drawing. The plotting area rectangle will be
//   computed to acheive the current aspect ratio and
//   allow for x and y axis labels and other area surrounding
//   the plot.

//    C2D_Transform* pT = dynamic_cast<C2D_Transform*>(m_pCt);

//    if (! pT)
    {
        if (pDC)
        {
            TEXTMETRIC tm;
            pDC->GetTextMetrics (&tm);

            wRect.TopLeft().x += 12*tm.tmAveCharWidth;
            wRect.BottomRight().x -= 5*tm.tmAveCharWidth;
            wRect.BottomRight().y -= 3*tm.tmHeight;

            // Determine aspect corrected size

            int y1 = wRect.BottomRight().y - wRect.Width()/m_fAspect;
            if (y1 < 2*tm.tmHeight) y1 = 2*tm.tmHeight;

            wRect.TopLeft().y = y1;
        }
    }

    (*m_qiView)->m_pCt->SetPhysical (wRect);
    // m_pGrid->SetTransform (*m_pCt);
}
//---------------------------------------------------------------

float CPlotDisplay::GetAspect()
{
// Return aspect ratio of current display

    CRect wRect = (*m_qiView)->m_pCt->GetPhysical();
    return (((float) wRect.Width())/wRect.Height());

}
//---------------------------------------------------------------

CPlot* CPlotDisplay::MakePlot(CDataset* ds, int plot_type)
{
    CPlot* p = NULL;

    switch (plot_type)
    {
        case 0:
          p = new CXyPlot(ds);
          break;
        default:
          ;
    }

    // Add to plot list

    if (p) m_pPlotList->AddPlot (p);
    return p;
}
//---------------------------------------------------------------

CPlot* CPlotDisplay::MakePlot (CWorkspace41* ws, CDataset* ds, int n)
{
// Create corresponding plot for plot n in a 4.1 workspace

    CPlot* p = NULL;

    p = new CXyPlot (ds);
    switch (ws->pv[n].sym)
    {
        case 'p':
          p->SetSymbol(sym_POINT);
          break;
        case 'l':
          p->SetSymbol(sym_LINE);
          break;
        case '+':
          p->SetSymbol(sym_LINE_PLUS_POINT);
          break;
        case 'S':
          p->SetSymbol(sym_STICK);
          break;
        default:
          ;
    }

    // Add to plot list

    if (p) m_pPlotList->AddPlot (p);
    return p;

}
//---------------------------------------------------------------

int CPlotDisplay::IndexOf (CPlot* p)
{
  // Return the vector index of the plot p in the display;
  // return -1 if plot is not found in the display.

  int nPlot = -1;
  if (p)
    {
      int i, n = Nplots();

      for (i = 0; i < n; i++)
	{
	  if ((*this)[i] == p) break;
	}
      if (i < n) nPlot = i;
    }
  return nPlot;
}
//----------------------------------------------------------------

void CPlotDisplay::DeletePlot ()
{
// Delete the active plot in the plot list

    CPlot* p = m_pPlotList->Active();

    m_pPlotList->RemovePlot(p);
    delete p;
}
//---------------------------------------------------------------

void CPlotDisplay::DeletePlotsOf (CDataset* d)
{
// Delete all plots which are associated with dataset d

    CPlot* p;

    while (p = m_pPlotList->PlotOf(d))
    {
        m_pPlotList->RemovePlot(p);

        delete p;
    }
}
//---------------------------------------------------------------

void CPlotDisplay::Draw(CDC *pDC)
{
    CPlotView* pView = *m_qiView;
    pView->m_pGrid->Draw(pDC);
    pView->m_pGrid->Labels(pDC);

    CRect rect = pView->m_pCt->GetPhysical();
    pDC->IntersectClipRect(&rect);  // enable clipping for plot area
    m_pPlotList->Draw(pDC);
    pDC->SelectClipRgn (NULL);      // disable clipping
}
//---------------------------------------------------------------

void CPlotDisplay::ResetExtrema()
{
// Set display extrema to encompass all data sets for
//   which there are plots

  vector<float> x = m_pPlotList->GetExtrema();
  (*m_qPV.begin())->SetExtrema(x);
  this->SetCoordinateDisplayFormat(x);
}
//---------------------------------------------------------------

void CPlotDisplay::ApplyCurrentView()
{
   CTransform* pT = (*m_qiView)->m_pCt;
   if (pT) {
     (*m_qiView)->m_pGrid->SetTransform(pT);
     vector<float> x = this->GetExtrema();
     this->SetCoordinateDisplayFormat(x);
   }
}

void CPlotDisplay::GoBack()
{
// Back up to the previous view in a circular fashion

    if (m_qiView > m_qPV.begin())
        --m_qiView;
    else
        m_qiView = m_qPV.end() - 1;

    ApplyCurrentView();
}
//---------------------------------------------------------------

void CPlotDisplay::GoForward()
{
// Move to the next view in the queue, in a circular fashion

    if (m_qiView < (m_qPV.end() - 1))
        ++m_qiView;
    else
        m_qiView = m_qPV.begin();

    ApplyCurrentView();
}
//---------------------------------------------------------------

void CPlotDisplay::DeleteView ()
{
// Delete the current view and go to previous one,
//   unless it is the first view.

    if (m_qiView > m_qPV.begin())
    {
	m_qPV.erase(m_qiView);
	--m_qiView;
	ApplyCurrentView();
    }
}
//---------------------------------------------------------------

CDataset* CPlotDisplay::GetActiveSet()
{
    CPlot* p = m_pPlotList->Active();
    if (p)
        return p->GetSet();
    else
        return NULL;
}

CDataset* CPlotDisplay::GetOperandSet()
{
    CPlot* p = m_pPlotList->Operand();
    if (p)
        return p->GetSet();
    else
        return NULL;
}
//---------------------------------------------------------------

void CPlotDisplay::SetColor(COLORREF cr)
{
    CPlot* p = m_pPlotList->Active();
    if (p) p->SetColor(cr);
}

void CPlotDisplay::SetSymbol(Symbol s)
{
    CPlot* p = m_pPlotList->Active();
    if (p) p->SetSymbol(s);
}
//---------------------------------------------------------------

int CPlotDisplay::Write (ofstream& ofile)
{
  // Write the plot display information to a file stream

  return 0;
}


// CPlotDisplay.h
//
// Header file for class CPlotDisplay
//
// Copyright 1996-2020 Krishna Myneni
//
// This software is provided under the terms of the
// GNU Affero General Public License (AGPL) v 3.0 or later.
//
#ifndef __CPLOTDISPLAY_H__
#define __CPLOTDISPLAY_H__

class CPlotDisplay {
    deque<CPlotView*> m_qPV;    // double ended queue of pointers to plot views
    deque<CPlotView*>::iterator m_qiView;  // iterator to current plot view
    CPlotList* m_pPlotList;     // the plot list
    float m_fAspect;            // plot display desired aspect ratio
public:
    CPoint m_nMousePt;
    char m_szXform[16];
    char m_szYform[16];

    CPlotDisplay ();
    ~CPlotDisplay ();
    CPlotView* GetCurrentView() { return (*m_qiView); }
    void CreateView (COORDINATE_SYSTEM, vector<float>);
    void ApplyCurrentView();
    void DeleteView ();
    void GoBack();
    void GoForward();
    void GoHome() {m_qiView = m_qPV.begin(); ApplyCurrentView();}
    int Nplots() {return m_pPlotList->Nplots();}
    void SetAspect (float aspect) {m_fAspect = aspect;}
    float GetAspect ();
    void SetPlotRect (CRect, CDC*);
    CRect GetPlotRect () {return (*m_qiView)->m_pCt->GetPhysical();}
    CPlot* SelectedPlot (CPoint p) {return m_pPlotList->Selection(p);}
    CDataset* GetActiveSet ();
    CDataset* GetOperandSet ();
    CPlot* GetActivePlot () {return m_pPlotList->Active();}
    CPlot* GetOperandPlot () {return m_pPlotList->Operand();}
    BOOL SetActivePlot (CPlot* p) {return m_pPlotList->SetActive(p);}
    BOOL SetOperandPlot (CPlot* p) {return m_pPlotList->SetOperand(p);}
    char* GetList () {return m_pPlotList->GetList();}
    void DisplayList (CDC* pDC) {m_pPlotList->DisplayList(pDC);}
    void Draw (CDC*);
    vector<float> Logical (CPoint p) {return (*m_qiView)->m_pCt->Logical(p);}
    vector<float> Logical (CRect r) {return (*m_qiView)->m_pCt->Logical(r);}
    void SetCoordinateDisplayFormat (vector<float> x);
    void SetExtrema (vector<float> x) {(*m_qiView)->SetExtrema(x);}
    vector<float> GetExtrema () {return (*m_qiView)->GetExtrema();}
    void ResetExtrema();
    void Reset();
    CPlot* MakePlot(CDataset*, int) ;
    CPlot* MakePlot (CWorkspace41*, CDataset*, int) ;
    void DeletePlot ();
    void DeletePlotsOf (CDataset*);
    int IndexOf (CPlot*);
    CPlot* operator[] (const int i) { return (*m_pPlotList)[i];}
    int Write (ofstream&);

    void SetColor (COLORREF cr);
    void SetSymbol (Symbol s);
    Symbol GetSymbol () {return m_pPlotList->Active()->GetSymbol();}
};

#endif

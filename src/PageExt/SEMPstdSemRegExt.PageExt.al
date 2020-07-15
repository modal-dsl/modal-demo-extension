pageextension 50132 "SEM Pstd. Sem. Reg. Ext." extends "SEM Posted Sem. Reg."
{
    layout
    {
        addafter("Instructor Code")
        {
            field("Instructor Name"; "Instructor Name")
            {
                ApplicationArea = All;
            }
        }
    }
}

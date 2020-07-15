pageextension 50130 "SEM Seminar Reg. Ext." extends "SEM Seminar Registration"
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

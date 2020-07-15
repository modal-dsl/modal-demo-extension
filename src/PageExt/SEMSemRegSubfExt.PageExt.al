pageextension 50131 "SEM Sem. Reg. Line Subf. Ext." extends "SEM Sem. Reg. Subf."
{
    layout
    {
        addafter("Participant Contact No.")
        {
            field("Participant Name"; "Participant Name")
            {
                ApplicationArea = All;
            }
        }
    }
}

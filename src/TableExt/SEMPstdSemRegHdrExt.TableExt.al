tableextension 50132 "SEM Pstd. Sem. Reg. Hdr. Ext." extends "SEM Pstd. Sem. Reg. Header"
{
    fields
    {
        field(50130; "Instructor Name"; Text[50])
        {
            Caption = 'Instructor Name';
            FieldClass = FlowField;
            CalcFormula = Lookup ("SEM Instructor".Name where(Code = field("Instructor Code")));
            Editable = false;
        }
        field(50131; "No. of Participants"; Integer)
        {
            Caption = 'No. of Participants';
            FieldClass = FlowField;
            CalcFormula = count ("SEM Sem. Reg. Line" where("Document No." = field("No.")));
            Editable = false;
        }
    }
}

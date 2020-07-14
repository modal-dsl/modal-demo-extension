tableextension 50133 "SEM Pstd. Sem. Reg. Line Ext." extends "SEM Pstd. Sem. Reg. Line"
{
    fields
    {
        field(50130; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Lookup (Contact.Name where("No." = field("Participant Contact No.")));
        }
    }
}

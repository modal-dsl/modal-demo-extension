tableextension 50131 "SEM Seminar Reg. Line Ext." extends "SEM Sem. Reg. Line"
{
    fields
    {
        modify("Participant Contact No.")
        {
            trigger OnAfterValidate()
            begin
                if "Participant Contact No." <> xRec."Participant Contact No." then
                    CalcFields("Participant Name");
            end;
        }
        field(50130; "Participant Name"; Text[100])
        {
            Caption = 'Participant Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Lookup (Contact.Name where("No." = field("Participant Contact No.")));
        }
    }

}

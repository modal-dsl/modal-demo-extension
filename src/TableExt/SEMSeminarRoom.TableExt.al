tableextension 50135 "SEM Seminar Room Ext." extends "SEM Seminar Room"
{
    fields
    {
        modify("Maximum Participants")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Maximum Participants")), "Maximum Participants", 0);
            end;
        }
    }

    var
        SeminarExtMgt: Codeunit "SEM Seminar Extensions Mgt.";
}

tableextension 50134 "SEM Seminar Ext." extends "SEM Seminar"
{
    fields
    {
        modify("Duration Days")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Duration Days")), "Duration Days", 0);
            end;
        }
        modify("Minimum Participants")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Minimum Participants")), "Minimum Participants", 0);
                SeminarExtMgt.CheckLessThan(
                    RecordId.GetRecord().Field(FieldNo("Minimum Participants")),
                    "Minimum Participants",
                    RecordId.GetRecord().Field(FieldNo("Maximum Participants")),
                    "Maximum Participants"
                );
            end;
        }
        modify("Maximum Participants")
        {
            trigger OnBeforeValidate()
            begin
                SeminarExtMgt.CheckMinValue(RecordId.GetRecord().Field(FieldNo("Maximum Participants")), "Maximum Participants", 0);
                SeminarExtMgt.CheckGreaterThan(
                    RecordId.GetRecord().Field(FieldNo("Maximum Participants")),
                    "Maximum Participants",
                    RecordId.GetRecord().Field(FieldNo("Minimum Participants")),
                    "Minimum Participants"
                );
            end;
        }
    }

    var
        SeminarExtMgt: Codeunit "SEM Seminar Extensions Mgt.";

}

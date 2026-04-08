using System;
using System.Collections.Generic;
using System.Text;

namespace DialogEditor.Models
{
    public class DialogueData
    {
        public List<DialogueEntry> Dialogues { get; set; }
        public DialogueMetadata Metadata { get; set; }
    }
}
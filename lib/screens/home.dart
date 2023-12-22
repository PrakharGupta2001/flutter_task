import 'package:flutter/material.dart';
import 'package:form_pdf/models/education_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  List<EducationEntry> educationEntries = [];
  DateTime selectedDate = DateTime.now();
  DateTime dob = DateTime.now();

  Future<void> selectEducationDate(BuildContext context) async {}

  Future<void> selectDOBDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: dob,
        firstDate: DateTime(1800, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
        dobController.text = DateFormat("dd-MM-yyyy").format(dob);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Generator App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: Text(
                      'Date of Birth: ${DateFormat("dd-MM-yyyy").format(dob)}'),
                ),
                ElevatedButton(
                    onPressed: () async {
                      await selectDOBDate(context);
                    },
                    child: Text('Change Date'))
              ],
            ),
            const SizedBox(height: 20),
            const Text('Educational History', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            educationEntries.isEmpty
                ? const Expanded(
                    child: Text('No Entries Yet'),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: educationEntries.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(educationEntries[index].institution),
                          subtitle:
                              Text('Degree: ${educationEntries[index].degree}\n'
                                  'Date: ${educationEntries[index].date}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                educationEntries.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _addEducationEntry();
              },
              child: const Text('Add Education Entry'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _generatePDF();
              },
              child: const Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }

  void _addEducationEntry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String institution = '';
        String degree = '';
        String date = DateFormat("dd-MM-yyyy").format(selectedDate);
        return StatefulBuilder(builder: (context, setDailogState) {
          return AlertDialog(
            title: const Text('Add Education Entry'),
            content: Column(
              children: [
                TextField(
                  onChanged: (value) => institution = value,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                TextField(
                  onChanged: (value) => degree = value,
                  decoration: const InputDecoration(labelText: 'Degree'),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Text(
                            'Date: ${DateFormat("dd-MM-yyyy").format(selectedDate)}'),
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(1800, 8),
                                lastDate: DateTime(2101));
                            if (picked != null && picked != selectedDate) {
                              setDailogState(() {
                                selectedDate = picked;
                                date = DateFormat("dd-MM-yyyy")
                                    .format(selectedDate);
                              });
                              setState(() {
                                date = DateFormat("dd-MM-yyyy")
                                    .format(selectedDate);
                              });
                            }
                          },
                          child: Text('Change Date'))
                    ])
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    educationEntries.add(EducationEntry(
                      institution: institution,
                      degree: degree,
                      date: date,
                    ));
                    print(
                        "educationEntries[0].date: ${educationEntries[0].date}");
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Bio Data'),
            ),
            pw.Paragraph(text: 'Name: ${nameController.text}'),
            pw.Paragraph(text: 'Date of Birth: ${dobController.text}'),
            pw.SizedBox(height: 10),
            pw.Header(
              level: 1,
              child: pw.Text('Educational History'),
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Institution', 'Degree', 'Date'],
                ...educationEntries.map(
                    (entry) => [entry.institution, entry.degree, entry.date]),
              ],
            ),
          ],
        ),
      ),
    );

    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/education_resume.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share the PDF
    Share.shareXFiles([XFile(file.path)]);
  }
}
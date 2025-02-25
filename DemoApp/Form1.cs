using System;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Diagnostics;

namespace DemoApp
{
    public partial class Form1 : Form
    {
        private string _connectionString = string.Empty;

        public Form1()
        {
            InitializeComponent();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void label2_Click(object sender, EventArgs e)
        {

        }

        private void button1_Click(object sender, EventArgs e)
        {
            DoSearch();
        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {

        }

        private async void Form1_Load(object sender, EventArgs e)
        {
            _connectionString = Environment.GetEnvironmentVariable("MSSQL") ?? string.Empty;
            Debug.Assert(!string.IsNullOrEmpty(_connectionString), "Connection string is empty");            

            await WarmupDatabaseLoginAsync();
        }

        private async Task WarmupDatabaseLoginAsync()
        {
            toolStripStatusLabel1.Text = "Connecting...";

            try
            {
                using SqlConnection connection = new(_connectionString);
                await connection.OpenAsync();
                await connection.CloseAsync();
                toolStripStatusLabel1.Text = "Connected";
                textBox1.Enabled = true;
                button1.Enabled = true;
            }
            catch (Exception ex)
            {
                toolStripStatusLabel1.Text = ex.Message;
            }
        }

        private void DoSearch()
        {
            button1.Text = "Searching...";
            button1.Enabled = false;

            try
            {
                dataGridView1.DataSource = null;
                dataGridView1.Rows.Clear();
                dataGridView1.Columns.Clear();

                button1.Text = "Connecting...";
                using SqlConnection connection = new(_connectionString);
                connection.Open();

                button1.Text = "Searching...";
                // Execute stored procedure
                using SqlCommand command = new("dbo.search_products", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@searchTerm", textBox1.Text);

                // Execute the query
                using SqlDataReader reader = command.ExecuteReader();

                // Create a DataTable to store the data
                DataTable dataTable = new();
                dataTable.Load(reader);
                // Bind the DataTable to the DataGridView
                dataGridView1.DataSource = dataTable;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
            finally
            {
                button1.Text = "Search";
                button1.Enabled = true;
            }
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void textBox1_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == (char)Keys.Enter)
            {
                DoSearch();
            }   
        }
    }
}

API yang mau kita hit

   public function getExecutionData (Request $request) {

    
    // untuk halaman execution ambil yang ditampilkan data dari table pics_schedule. untuk unint yang akan dieksekusi.
    // untuk setiap unit yang akan dieksekusi akan dibagi per part_of_check. oleh karena itu setiap row akan dibagi sebgai sebanyak part_of_check(POC) nya 

    // untuk mekanik mengeksekusi maka dibuatkan tombol dari POC tadi. permasalahannya karena ini multi user sehingga akan ada POC yang dikerjakan oleh user lain. oleh karena itu
    // perlu kondisi untuk button button ini.. jika sudah ada datanya maka tidak bisa lagi dibukan oleh user lain. untuk memfasilitasi hal tersebut maka dilakukan query lagi sekali 
    // ke table pics_result untuk mengecek apakah POC dari schedule ini sudah dikerjakan atau belum.
    // sehingga akan ada n+poc problem disini.
    // bahkan karena satu schedule dipecah jadi beberapa POC maka akan jadi n*poc+1 problem.

    // Perlu dibuatkan query yang efisien untuk mengambil data ini. seperti dibawah ini.

    // berarti jika menggunakan table yang dijoin sebagai where. maka table di kiri akan hilang jika dia tidak memiliki hasil join. yang mana seharusnya muncul karena ini left join. tapi karena wherenya ke tabel di sebelebah kanan maka dia akan hilang. apakah saya benar?

    /**
     * Helper class untuk membuat WHERE clause + bindings yang lebih kompleks
     * Mendukung 4 tipe: 'schedule', 'execution', 'validation', 'history'
     *
    * Usage:
    *  use App\Http\Controllers\Pics\Api\apiHelper;
    *  $whereData = apiHelper::generateWhereClauseWithBindings(
    *      'execution', $userSections, null, '2024-06-20', 1, 'search-term'
    *  );
    *  $sql = "SELECT ... FROM pics_schedule s LEFT JOIN pics_equipment e ON s.equipment_id = e.id";
    *  if ($whereData['sql']) $sql .= ' WHERE ' . $whereData['sql'];
    *  $rows = DB::select($sql, $whereData['bindings']);
    */

    $whereData = apiHelper::generateWhereClauseWithBindings(
        'execution', "PLANT PRIME MOVER", null, "2025-12-20" /*Carbon::today()->toDateString()*/, 1, "HT140-04"
    );


        $today = Carbon::today()->toDateString();

    Config::set('database.default', 'db_pltmp_doc');

    $rows = DB::table('pics_schedule as s')
        ->selectRaw('MAX(s.date) as date, e.eq_numb, e.section, MAX(s.id) as action')
        ->leftJoin('equipment as e', 's.equipment_id', '=', 'e.id')
        // ->whereDate('s.date', '<=', $today)
        ->whereRaw($whereData['sql'], $whereData['bindings'])
        ->groupBy('e.eq_numb', 'e.section')
        ->orderByDesc('date')
        ->orderBy('e.eq_numb', 'asc')
        ->get();

    $id_schedule = $rows->pluck('action');

    
    
    
    // return response()->json($rows);
    // return response()->json($id_schedule);
    
    if (!empty($id_schedule)) {
        $resultPerSchedule = DB::table('pics_result as r')
            ->leftJoin('pics_item as i', 'r.item_id', '=', 'i.id')
            ->select(
                'r.*',
                'i.part_of_check',
                )
            ->whereIn('r.schedule_id', $id_schedule)
            ->get()
            ->groupBy('schedule_id');
    } else {
        $resultPerSchedule = collect();
    }

    // return response()->json($resultPerSchedule);

    $enrichedRows = $rows->map(function ($row) use ($resultPerSchedule){

        $id_schedule = $row->action;

        // buat/instansiasi class std baru 
        $obj = new stdClass();
        $obj->date = $row->date;
        $obj->section = $row->section;
        $obj->eq_numb = $row->eq_numb;
        // $obj->action = $row->action;  kalo mau kaya awal. sama aja boong
        // $resultSingleSchedule = $resultPerSchedule->get($id_schedule, collect())->values()->toArray(); 
        $resultSingleSchedule = $resultPerSchedule->get($id_schedule, collect())
            ->map(function($r) {
                 return  [$r->id, $r->part_of_check, $r->inspector];
          })
        
        ->values()->toArray(); 

        $obj->{$id_schedule} = $resultSingleSchedule;

        return $obj;


    });


    return response()->json($enrichedRows);


}